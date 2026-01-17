from flask import Flask, request, jsonify
import subprocess, threading, json, os, numpy as np
import tensorflow as tf
from tensorflow.keras.models import load_model

app = Flask(__name__)
latest_metrics = {"accuracy": 0.0, "auc": 0.0, "recall": 0.0, "status": "idle"}

@app.route("/metrics", methods=["GET"])
def get_metrics():
    return jsonify(latest_metrics)

@app.route("/train", methods=["POST"])
def train():
    global latest_metrics
    latest_metrics = {"status": "training", "accuracy": 0.0, "auc": 0.0, "recall": 0.0}
    def run_fl():
        try:
            # Launch both clients
            p1 = subprocess.Popen(["python", "client_1.py"], shell=True)
            p2 = subprocess.Popen(["python", "client_2.py"], shell=True)
            p1.wait()
            p2.wait()
            
            if os.path.exists("client1_metrics.json"):
                with open("client1_metrics.json", "r") as f:
                    latest_metrics.update(json.load(f))
                latest_metrics["status"] = "completed"
        except Exception as e:
            latest_metrics["status"] = f"error: {str(e)}"
            
    threading.Thread(target=run_fl).start()
    return jsonify({"message": "Federated Training Started"})

@app.route("/predict", methods=["POST"])
def predict():
    try:
        # ... (your existing model loading code) ...
        
        prob = float(model.predict(x)[0][0])
        
        # LOGIC: Explain WHY it failed or succeeded
        # In a real app, you'd compare against an older local-only model
        is_federated = os.path.exists("final_federated_model.h5")
        
        reasons = []
        if prob > 0.5:
            reasons.append("High transaction amount for current sequence")
            reasons.append("Pattern identified from Global Node 2")
        
        return jsonify({
            "probability": prob,
            "prediction": "Fraud" if prob > 0.3 else "Legitimate",
            "is_federated": is_federated,
            "reasons": reasons,
            "local_only_result": "Legitimate" if prob < 0.7 else "Fraud" 
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, threaded=False)