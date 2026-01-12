import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense, Dropout, Bidirectional


# 🔥 FOCAL LOSS (IMPORTANT)
def focal_loss(gamma=2.0, alpha=0.25):
    def loss(y_true, y_pred):
        y_true = tf.cast(y_true, tf.float32)

        # Binary cross entropy
        bce = tf.keras.backend.binary_crossentropy(y_true, y_pred)

        # p_t calculation
        p_t = y_true * y_pred + (1 - y_true) * (1 - y_pred)

        # Focal loss
        loss = alpha * tf.pow((1 - p_t), gamma) * bce
        return loss

    return loss


# 🔥 FINAL IMPROVED MODEL
def build_model(input_shape):
    model = Sequential([
        Bidirectional(LSTM(64), input_shape=input_shape),
        Dropout(0.3),
        Dense(1, activation="sigmoid")
    ])

    model.compile(
        optimizer="adam",
        loss=focal_loss(),     # ✅ CHANGED HERE
        metrics=["accuracy"]
    )

    return model
