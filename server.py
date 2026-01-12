import flwr as fl
import tensorflow as tf
from flwr.common import parameters_to_ndarrays
from model.fraud_lstm import build_model

# -------------------------
# CONFIG
# -------------------------
NUM_ROUNDS = 3
INPUT_SHAPE = (5, 401)  # (SEQ_LEN, FEATURES)

# -------------------------
# Custom Strategy
# -------------------------
class SaveModelStrategy(fl.server.strategy.FedAvg):

    def __init__(self):
        super().__init__()
        self.model = build_model(INPUT_SHAPE)

    def aggregate_fit(self, server_round, results, failures):
        aggregated = super().aggregate_fit(server_round, results, failures)

        if aggregated is not None:
            parameters, _ = aggregated

            # ✅ Convert Parameters → NumPy arrays
            weights = parameters_to_ndarrays(parameters)

            self.model.set_weights(weights)

            # ✅ Save model after final round
            if server_round == NUM_ROUNDS:
                self.model.save("final_federated_model.h5")
                print("\n✅ Final federated model saved as final_federated_model.h5\n")

        return aggregated

# -------------------------
# Start Server
# -------------------------
strategy = SaveModelStrategy()

fl.server.start_server(
    server_address="localhost:8080",
    config=fl.server.ServerConfig(num_rounds=NUM_ROUNDS),
    strategy=strategy
)
