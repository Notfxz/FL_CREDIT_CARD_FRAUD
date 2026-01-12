from flask import Flask, request, jsonify
import subprocess
import threading

app = Flask(__name__)

# ================================
# Shared metrics state
# ================================
latest_metrics = {
    "accuracy": 0.0,
    "auc": 0.0,
    "recall": 0.0,
    "status": "idle"
}

training_lock = threading.Lock()


# ================================
# Background training runner
# ================================
def run_training(client_file):
    global latest_metrics

    with training_lock:
        latest_metrics["status"] = "training"

    process = subprocess.Popen(
        ["python", client_file],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1
    )

    # Read Flower client output line by line
    for line in process.stdout:
        line = line.strip()
        print(line)

        # Example line:
        # 📊 Client-1 Best | AUC: 0.5581 | Recall: 0.9909 | Accuracy: 0.1747 | Threshold: 0.4
        if "AUC:" in line and "Recall:" in line and "Accuracy:" in line:
            try:
                parts = line.split("|")
                auc = float(parts[1].split(":")[1])
                recall = float(parts[2].split(":")[1])
                accuracy = float(parts[3].split(":")[1])

                with training_lock:
                    latest_metrics["auc"] = auc
                    latest_metrics["recall"] = recall
                    latest_metrics["accuracy"] = accuracy
                    latest_metrics["status"] = "training"

            except Exception as e:
                print("⚠️ Metric parsing error:", e)

    process.wait()

    with training_lock:
        latest_metrics["status"] = "completed"


# ================================
# API: start training
# ================================
@app.route("/train", methods=["POST"])
def train():
    global latest_metrics

    data = request.get_json(silent=True) or {}
    client_id = data.get("client_id", "client_1")

    client_file = "client_1.py" if client_id == "client_1" else "client_2.py"

    with training_lock:
        if latest_metrics["status"] == "training":
            return jsonify({"message": "Training already running"}), 409

        latest_metrics = {
            "accuracy": 0.0,
            "auc": 0.0,
            "recall": 0.0,
            "status": "training"
        }

    thread = threading.Thread(
        target=run_training,
        args=(client_file,),
        daemon=True
    )
    thread.start()

    return jsonify({
        "message": "Training started",
        "client": client_id
    })


# ================================
# API: fetch metrics
# ================================
@app.route("/metrics", methods=["GET"])
def metrics():
    with training_lock:
        return jsonify(latest_metrics)


# ================================
# Main
# ================================
if __name__ == "__main__":
    print("🚀 Client API running on http://127.0.0.1:8000")
    app.run(host="0.0.0.0", port=8000)
