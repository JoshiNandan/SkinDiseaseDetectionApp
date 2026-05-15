import joblib

disease_encoder = joblib.load("disease_encoder.pkl")

print(disease_encoder.classes_)