import flwr as fl
import os
from model.fraud_lstm import build_model

class SaveModelStrategy(fl.server.strategy.FedAvg):
    def __init__(self):
        super().__init__(
            min_fit_clients=2,           # Wait for both clients to start training
            min_available_clients=2,     # Wait for both clients to connect
            min_evaluate_clients=2,      # Wait for both clients to evaluate
        )
        self.model = build_model((5, 401))

    def aggregate_fit(self, server_round, results, failures):
        aggregated_weights = super().aggregate_fit(server_round, results, failures)
        if aggregated_weights is not None:
            print(f"Saving round {server_round} weights...")
            self.model.set_weights(fl.common.parameters_to_ndarrays(aggregated_weights[0]))
            self.model.save("final_federated_model.h5")
        return aggregated_weights

strategy = SaveModelStrategy()

if __name__ == "__main__":
    print("Server starting on port 8080...")
    fl.server.start_server(
        server_address="0.0.0.0:8080",
        config=fl.server.ServerConfig(num_rounds=10),
        strategy=strategy
    )