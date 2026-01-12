# Federated Learning for Credit Card Fraud Detection

This project implements a Federated Learning (FL) framework to detect fraudulent transactions while keeping data decentralized.

## Project Structure
* `server.py`: The central server that aggregates model weights.
* `client_1.py` & `client_2.py`: Clients that train the model on local data.
* `model/`: Contains the LSTM model architecture.
* `preprocessing/`: Scripts for data cleaning and sequence generation.

## How to Run
1. **Install Dependencies:**
   `pip install tensorflow pandas numpy scikit-learn`
2. **Start the Server:**
   `python server.py`
3. **Start the Clients:**
   Open new terminals and run:
   `python client_1.py`
   `python client_2.py`
