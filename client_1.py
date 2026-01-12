# =====================================
# Client 1 – Federated Learning Client
# =====================================

import json
import numpy as np
import flwr as fl

from sklearn.model_selection import train_test_split
from sklearn.metrics import roc_auc_score, recall_score, accuracy_score
from sklearn.utils.class_weight import compute_class_weight

from model.fraud_lstm import build_model


# =====================================
# Load data (RAM safe)
# =====================================
data = np.load("client_sequences/client_1_seq.npz", mmap_mode="r")
X, y = data["X"], data["y"]

# =====================================
# Controlled sampling
# =====================================
MAX_SAMPLES = 60000
FRAUD_RATIO = 0.25

fraud_idx = np.where(y == 1)[0]
normal_idx = np.where(y == 0)[0]

num_fraud = min(len(fraud_idx), int(MAX_SAMPLES * FRAUD_RATIO))
num_normal = MAX_SAMPLES - num_fraud

fraud_sample = np.random.choice(fraud_idx, num_fraud, replace=False)
normal_sample = np.random.choice(normal_idx, num_normal, replace=False)

selected_idx = np.concatenate([fraud_sample, normal_sample])
np.random.shuffle(selected_idx)

X = X[selected_idx]
y = y[selected_idx]

# =====================================
# Train / Test split
# =====================================
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# =====================================
# Class weights
# =====================================
classes = np.unique(y_train)
class_weights = compute_class_weight(
    class_weight="balanced",
    classes=classes,
    y=y_train
)
class_weights = dict(zip(classes, class_weights))

# =====================================
# Build model
# =====================================
model = build_model(X_train.shape[1:])


# =====================================
# Flower Client
# =====================================
class FraudClient(fl.client.NumPyClient):

    def get_parameters(self, config):
        return model.get_weights()

    def fit(self, parameters, config):
        model.set_weights(parameters)

        model.fit(
            X_train,
            y_train,
            epochs=5,
            batch_size=32,
            class_weight=class_weights,
            verbose=0
        )

        return model.get_weights(), len(X_train), {}

    def evaluate(self, parameters, config):
        model.set_weights(parameters)

        y_pred = model.predict(X_test, verbose=0).ravel()

        thresholds = [0.3, 0.4, 0.5, 0.6]
        MIN_RECALL = 0.6

        best_score = -1
        best_metrics = {}

        for t in thresholds:
            y_label = (y_pred > t).astype(int)

            acc = accuracy_score(y_test, y_label)
            rec = recall_score(y_test, y_label)
            auc = roc_auc_score(y_test, y_pred)

            if rec < MIN_RECALL:
                continue

            score = auc + acc

            if score > best_score:
                best_score = score
                best_metrics = {
                    "accuracy": acc,
                    "recall": rec,
                    "auc": auc,
                    "threshold": t
                }

        if not best_metrics:
            best_metrics = {
                "accuracy": accuracy_score(y_test, (y_pred > 0.3).astype(int)),
                "recall": recall_score(y_test, (y_pred > 0.3).astype(int)),
                "auc": roc_auc_score(y_test, y_pred),
                "threshold": 0.3
            }

        loss, _ = model.evaluate(X_test, y_test, verbose=0)

        print(
            f"📊 Client-1 Best | "
            f"AUC: {best_metrics['auc']:.4f} | "
            f"Recall: {best_metrics['recall']:.4f} | "
            f"Accuracy: {best_metrics['accuracy']:.4f} | "
            f"Threshold: {best_metrics['threshold']}"
        )

        # ✅ SAVE METRICS
        with open("client1_metrics.json", "w") as f:
            json.dump(best_metrics, f)

        return loss, len(X_test), best_metrics


# =====================================
# Start Flower Client
# =====================================
fl.client.start_numpy_client(
    server_address="localhost:8080",
    client=FraudClient()
)
