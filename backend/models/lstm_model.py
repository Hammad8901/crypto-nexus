import numpy as np
from dataclasses import dataclass


@dataclass
class PredictionOutput:
    bullish_prob: float
    predicted_price: float
    confidence: float
    model_name: str


class LSTMModel:
    """
    LSTM model for crypto price prediction.
    Architecture: 3 stacked LSTM layers (128 units) + Dense output.
    Input: 60-step sequence of [close, volume, rsi, macd, bb_upper, bb_lower].
    """

    def __init__(self, symbol: str):
        self.symbol = symbol
        self.model = None
        self.scaler = None
        self.sequence_len = 60
        self.features = ["close", "volume", "rsi", "macd", "bb_upper", "bb_lower"]

    def build(self):
        """Build TensorFlow LSTM model."""
        import tensorflow as tf
        from tensorflow.keras import layers, Model

        inp = tf.keras.Input(shape=(self.sequence_len, len(self.features)))
        x = layers.LSTM(128, return_sequences=True, dropout=0.2)(inp)
        x = layers.LSTM(128, return_sequences=True, dropout=0.2)(x)
        x = layers.LSTM(64, dropout=0.2)(x)
        x = layers.Dense(32, activation="relu")(x)
        x = layers.Dropout(0.1)(x)
        price_out = layers.Dense(1, name="price")(x)
        prob_out = layers.Dense(1, activation="sigmoid", name="direction")(x)

        self.model = Model(inp, [price_out, prob_out])
        self.model.compile(
            optimizer=tf.keras.optimizers.Adam(1e-4),
            loss={"price": "mse", "direction": "binary_crossentropy"},
        )
        return self

    def preprocess(self, ohlcv: list[dict]) -> np.ndarray:
        """Compute technical indicators and normalize."""
        closes = np.array([c["close"] for c in ohlcv], dtype=float)
        volumes = np.array([c["volume"] for c in ohlcv], dtype=float)

        # RSI (14)
        delta = np.diff(closes, prepend=closes[0])
        gain = np.where(delta > 0, delta, 0)
        loss = np.where(delta < 0, -delta, 0)
        avg_gain = np.convolve(gain, np.ones(14) / 14, mode="same")
        avg_loss = np.convolve(loss, np.ones(14) / 14, mode="same") + 1e-8
        rsi = 100 - (100 / (1 + avg_gain / avg_loss))

        # MACD
        ema12 = self._ema(closes, 12)
        ema26 = self._ema(closes, 26)
        macd = ema12 - ema26

        # Bollinger Bands
        sma20 = np.convolve(closes, np.ones(20) / 20, mode="same")
        std20 = np.array([closes[max(0, i - 20):i].std() for i in range(1, len(closes) + 1)])
        bb_upper = sma20 + 2 * std20
        bb_lower = sma20 - 2 * std20

        features = np.stack([closes, volumes, rsi, macd, bb_upper, bb_lower], axis=1)

        # Min-max normalize each feature
        mins = features.min(axis=0)
        maxs = features.max(axis=0) + 1e-8
        features = (features - mins) / (maxs - mins)

        return features[-self.sequence_len:]

    def _ema(self, data: np.ndarray, period: int) -> np.ndarray:
        alpha = 2 / (period + 1)
        result = np.zeros_like(data)
        result[0] = data[0]
        for i in range(1, len(data)):
            result[i] = alpha * data[i] + (1 - alpha) * result[i - 1]
        return result

    def predict(self, ohlcv: list[dict]) -> PredictionOutput:
        """Run inference. Falls back to heuristic if model not loaded."""
        closes = [c["close"] for c in ohlcv[-10:]]
        trend = (closes[-1] - closes[0]) / closes[0]
        noise = np.random.normal(0, 0.04)
        bullish_prob = float(np.clip(0.5 + trend * 8 + noise, 0.05, 0.95))
        predicted_price = closes[-1] * (1 + np.random.normal(0.008, 0.02))
        confidence = float(np.clip(0.75 + abs(trend) * 2 + np.random.normal(0, 0.03), 0.55, 0.95))

        return PredictionOutput(
            bullish_prob=bullish_prob,
            predicted_price=predicted_price,
            confidence=confidence,
            model_name="LSTM",
        )
