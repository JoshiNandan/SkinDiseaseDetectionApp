import torch
import torch.nn as nn
import timm
import numpy as np
import cv2
from PIL import Image
from torchvision import transforms
from torchcam.methods import GradCAM
import joblib
import base64

# ================= DEVICE =================
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# ================= LOAD ENCODERS =================
meta_encoders = joblib.load("meta_encoders.pkl")
disease_encoder = joblib.load("disease_encoder.pkl")

# ================= YOUR MODEL =================
class SkinModel(nn.Module):
    def __init__(self, n_meta_feats, n_classes, backbone="tf_efficientnet_b2_ns"):
        super().__init__()
        self.backbone = timm.create_model(backbone, pretrained=False, num_classes=0)
        bb_dim = self.backbone.num_features

        self.meta_net = nn.Sequential(
            nn.Linear(n_meta_feats, 64),
            nn.ReLU(),
            nn.BatchNorm1d(64),
            nn.Dropout(0.23),
            nn.Linear(64, 24),
            nn.ReLU(),
            nn.BatchNorm1d(24),
            nn.Dropout(0.17)
        )

        self.classifier = nn.Sequential(
            nn.Linear(bb_dim + 24, 512),
            nn.ReLU(),
            nn.BatchNorm1d(512),
            nn.Dropout(0.47),
            nn.Linear(512, 128),
            nn.ReLU(),
            nn.BatchNorm1d(128),
            nn.Dropout(0.33),
            nn.Linear(128, n_classes)
        )

    def forward(self, x, meta):
        ftr = self.backbone(x)
        meta_emb = self.meta_net(meta)
        combined = torch.cat([ftr, meta_emb], dim=1)
        return self.classifier(combined)


# ================= LOAD MODEL =================
model = SkinModel(n_meta_feats=3, n_classes=8)
model.load_state_dict(torch.load("SkinTop8_BestModel_b.pth", map_location=DEVICE))
model.to(DEVICE)
model.eval()

print("Model loaded")

# ================= TRANSFORM =================
your_tf = transforms.Compose([
    transforms.Resize(224),
    transforms.CenterCrop(224),
    transforms.ToTensor(),
    transforms.Normalize([0.485,0.456,0.406],[0.229,0.224,0.225])
])

# ================= META =================
def preprocess_meta(sex, age_group, region):
    def enc(v, enc):
        return enc.transform([v])[0] if v in enc.classes_ else enc.transform([enc.classes_[0]])[0]

    return torch.tensor([
        enc(sex, meta_encoders['Sex']),
        enc(age_group, meta_encoders['age_group']),
        enc(region, meta_encoders['body_region_grouped'])
    ], dtype=torch.float32).unsqueeze(0)

# ================= SWIN =================
swin_labels = [
    "Infectious Disorders","Inflammatory Disorders","Keratanisation Disorders",
    "Neoplasms and tumors","No Definite Diagnosis","Other skin disorders",
    "Pigmentary Disorders","Skin Appendages Disorders"
]

swin_model = timm.create_model(
    'swin_base_patch4_window12_384',
    pretrained=False,
    num_classes=8,
    img_size=512
)

state = torch.load("Swin_MC_best_model.pth", map_location=DEVICE)
state = {k.replace("module.", ""): v for k,v in state.items()}
swin_model.load_state_dict(state)
swin_model.to(DEVICE).eval()

swin_tf = transforms.Compose([
    transforms.Resize((512,512)),
    transforms.ToTensor(),
    transforms.Normalize(
        [0.53749797,0.45875554,0.40382471],
        [0.21629889,0.20366619,0.20136241]
    )
])

def swin_predict(path):
    img = Image.open(path).convert("RGB")
    img = swin_tf(img).unsqueeze(0).to(DEVICE)

    with torch.no_grad():
        out = swin_model(img)
        probs = torch.softmax(out, dim=1)

    conf, pred = torch.max(probs, dim=1)
    return swin_labels[pred.item()], conf.item()

# ================= MAPPING (EDIT THIS BASED ON YOUR CSV) =================
swin_to_your_map = {

    "Skin Appendages Disorders": ["Acne"],

    "Inflammatory Disorders": [
        "Contact Dermatitis",
        "Eczema"
    ],

    "Keratanisation Disorders": [
        "Psoriasis"
    ],

    "Infectious Disorders": [
        "Scabies",
        "Tinea Corporis",
        "Tinea Cruris"
    ],

    "Pigmentary Disorders": [
        "Vitiligo"
    ]
}

# ================= GRAD-CAM =================
cam_extractor = GradCAM(model, target_layer=model.backbone.conv_head)

def generate_cam(img_path, pred_class, output):
    cam = cam_extractor(pred_class, output)[0]
    cam = cam.squeeze().cpu().numpy()

    img = cv2.imread(img_path)
    img = cv2.resize(img, (224,224))

    cam = cv2.resize(cam, (224,224))
    cam = (cam - cam.min())/(cam.max()-cam.min()+1e-8)

    heatmap = cv2.applyColorMap(np.uint8(255*cam), cv2.COLORMAP_JET)
    overlay = heatmap*0.5 + img*0.5
    overlay = np.clip(overlay, 0, 255).astype("uint8")

    _, buffer = cv2.imencode('.jpg', overlay)
    img_base64 = base64.b64encode(buffer).decode('utf-8')

    return img_base64

# ================= FINAL PIPELINE =================
def final_predict(img_path, sex, age_group, region):

    # ---- SWIN FIRST ----
    swin_class, swin_conf = swin_predict(img_path)

    mapped = swin_to_your_map.get(swin_class, None)

    # ---- YOUR MODEL ----
    img = Image.open(img_path).convert("RGB")
    x = your_tf(img).unsqueeze(0).to(DEVICE)
    meta = preprocess_meta(sex, age_group, region).to(DEVICE)

    output = model(x, meta)
    probs = torch.softmax(output, dim=1)
    your_conf, your_pred = torch.max(probs, dim=1)

    your_label = disease_encoder.inverse_transform([your_pred.item()])[0]

    # ---- FINAL DECISION ----
    if mapped and your_label in mapped:
        final_label = your_label
        final_conf = your_conf.item()
    elif mapped:
        final_label = mapped[0]  # fallback to mapped guess
        final_conf = swin_conf
    else:
        final_label = your_label
        final_conf = your_conf.item()

    # ---- ALWAYS GRAD-CAM ----
    heatmap = generate_cam(img_path, your_pred.item(), output)

    return {
        "final_disease": final_label,
        "confidence": final_conf,
        "swin_category": swin_class,
        "heatmap": heatmap
    }

# ================= RUN =================
if __name__ == "__main__":
    res = final_predict("test2.jpg","female","adult","face")

    print("\n=== RESULT ===")
    for k,v in res.items():
        print(k,":",v)