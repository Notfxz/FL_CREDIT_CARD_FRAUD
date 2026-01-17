import json
import numpy as np
import flwr as fl
import os
from sklearn.model_selection import train_test_split
from sklearn.metrics import roc_auc_score, recall_score, accuracy_score
from model.fraud_lstm import build_model

# 1. Load data
# CHANGE THIS TO client_2_seq.npz for the second client script
data = np.load("client_sequences/client_1_seq.npz", mmap_mode="r")
X, y = data["X"], data["y"]

# 2. Aggressive Balanced Sampling
MAX_SAMPLES = 2000 
FRAUD_RATIO = 0.5 # 50/50 split to force the model to see more fraud
fraud_idx = np.where(y == 1)[0]
normal_idx = np.where(y == 0)[0]

num_fraud = min(len(fraud_idx), int(MAX_SAMPLES * FRAUD_RATIO))
num_normal = MAX_SAMPLES - num_fraud

selected_idx = np.concatenate([
    np.random.choice(fraud_idx, num_fraud, replace=False),
    np.random.choice(normal_idx, num_normal, replace=False)
])
np.random.shuffle(selected_idx)
X, y = X[selected_idx], y[selected_idx]

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)

# 3. Aggressive Class Weights (The "Hammer" Fix for Recall)
# We tell the model that missing 1 Fraud is 15x worse than a false alarm
class_weights = {0: 1.0, 1: 15.0}

# 4. Build Model
model = build_model(X_train.shape[1:])

class FraudClient(fl.client.NumPyClient):
    def get_parameters(self, config):
        return model.get_weights()

    def fit(self, parameters, config):
        model.set_weights(parameters)
        # Smaller batch_size (32) helps the model learn minority patterns better
        model.fit(X_train, y_train, epochs=10, batch_size=32, 
                  class_weight=class_weights, verbose=1)
        return model.get_weights(), len(X_train), {}

    def evaluate(self, parameters, config):
        model.set_weights(parameters)
        y_pred = model.predict(X_test, verbose=0).ravel()
        
        # Recall-First Thresholding: We check multiple thresholds and pick the best recall
        best_rec = 0
        best_metrics = {}
        
        for t in [0.2, 0.3, 0.4, 0.5]:
            y_label = (y_pred > t).astype(int)
            rec = recall_score(y_test, y_label)
            acc = accuracy_score(y_test, y_label)
            auc = roc_auc_score(y_test, y_pred)
            
            if rec >= best_rec: # Prioritize the threshold that catches more fraud
                best_rec = rec
                best_metrics = {"accuracy": float(acc), "recall": float(rec), "auc": float(auc), "threshold": t}

        print(f"📊 Client Metrics | AUC: {best_metrics['auc']:.4f} | RECALL: {best_metrics['recall']:.4f} | Acc: {best_metrics['accuracy']:.4f}")
        
        # CHANGE TO client2_metrics.json for the second client script
        with open("client1_metrics.json", "w") as f:
            json.dump(best_metrics, f)
            
        loss, _ = model.evaluate(X_test, y_test, verbose=0)
        return float(loss), len(X_test), best_metrics

if __name__ == "__main__":
    fl.client.start_numpy_client(server_address="localhost:8080", client=FraudClient())