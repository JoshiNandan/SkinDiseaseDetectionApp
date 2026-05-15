import io
import base64
from fastapi import FastAPI, UploadFile, File, Form
from PIL import Image
import uvicorn
import os
from huggingface_hub import InferenceClient
# ===== IMPORT YOUR MODEL PIPELINE =====
from final import final_predict

def classify_age_group(age: int):
    if age <= 2:
        return "infant"
    elif age <= 12:
        return "child"
    elif age <= 25:
        return "young adult"
    elif age <= 45:
        return "adult"
    else:
        return "elderly"

def classify_body_region(region: str) -> str:
    region = region.lower()
    if any(x in region for x in ["abdomen", "chest", "back", "trunk"]):
        return "trunk"
    if any(x in region for x in ["leg", "thigh", "knee", "foot"]):
        return "lower extremities"
    if any(x in region for x in ["arm", "shoulder", "hand"]):
        return "upper extremities"
    if any(x in region for x in ["head", "face", "scalp"]):
        return "head/face"
    if "neck" in region:
        return "neck"
    if any(x in region for x in ["groin", "genital"]):
        return "genital/groin"
    return "other"


app = FastAPI(title="Skin AI API")

# ===== ROOT =====
@app.get("/")
def root():
    return {"status": "API Running"}

# ===== MAIN ENDPOINT =====
@app.post("/predict")
async def predict(
    image: UploadFile = File(...),
    sex: str = Form(...),
    age: int = Form(...),
    region: str = Form(...)
):

    # ===== SAVE TEMP IMAGE =====
    contents = await image.read()
    img = Image.open(io.BytesIO(contents)).convert("RGB")

    temp_path = "temp.jpg"
    img.save(temp_path)

    # ===== MODEL =====
    age_group = classify_age_group(age)
    body_region = classify_body_region(region)
    result = final_predict(temp_path, sex, age_group, body_region)

    disease = result["final_disease"]
    confidence = result["confidence"]

    # ===== CLEAN TEMP =====
    if os.path.exists(temp_path):
        os.remove(temp_path)

    return {
        "disease": disease,
        "confidence": confidence,
        "heatmap": result["heatmap"]
    }


# ===== RUN =====
if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000)

    