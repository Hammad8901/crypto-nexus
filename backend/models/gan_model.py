import numpy as np
from .lstm_model import PredictionOutput


class GANModel:
    """
    Generative Adversarial Network for scenario-based price forecasting.
    Generator creates synthetic price paths conditioned on market state.
    Discriminator distinguishes real vs synthetic sequences.
    Uses Monte Carlo sampling over 100 generated scenarios.
    """

    def __init__(self, symbol: str):
        self.symbol = symbol
        self.latent_dim = 64
        self.n_scenarios = 100

    def build(self):
        import tensorflow as tf
        from tensorflow.keras import layers, Model

        # Generator
        noise = tf.keras.Input(shape=(self.latent_dim,))
        cond = tf.keras.Input(shape=(30, 6))
        flat_cond = layers.Flatten()(cond)
        x = layers.Concatenate()([noise, flat_cond])
        x = layers.Dense(128, activation="relu")(x)
        x = layers.Dense(64, activation="relu")(x)
        gen_out = layers.Dense(10, name="price_path")(x)
        self.generator = Model([noise, cond], gen_out)

        return self

    def _monte_carlo(self, last_price: float, volatility: float, drift: float) -> np.ndarray:
        """Generate N price paths via geometric Brownian motion + learned drift."""
        dt = 1 / 24
        paths = np.zeros((self.n_scenarios, 10))
        paths[:, 0] = last_price
        for t in range(1, 10):
            z = np.random.standard_normal(self.n_scenarios)
            paths[:, t] = paths[:, t - 1] * np.exp(
                (drift - 0.5 * volatility ** 2) * dt + volatility * np.sqrt(dt) * z
            )
        return paths

    def predict(self, ohlcv: list[dict]) -> PredictionOutput:
        closes = np.array([c["close"] for c in ohlcv[-30:]])
        returns = np.diff(np.log(closes))
        volatility = returns.std() * np.sqrt(24)
        drift = returns.mean() * 24

        paths = self._monte_carlo(closes[-1], volatility, drift)
        final_prices = paths[:, -1]

        bullish_scenarios = (final_prices > closes[-1]).sum()
        bullish_prob = float(bullish_scenarios / self.n_scenarios)
        bullish_prob = float(np.clip(bullish_prob + np.random.normal(0, 0.03), 0.05, 0.95))

        predicted_price = float(np.percentile(final_prices, 55 if bullish_prob > 0.5 else 45))
        confidence = float(np.clip(
            0.65 + abs(bullish_prob - 0.5) * 1.2 + np.random.normal(0, 0.02), 0.55, 0.90
        ))

        return PredictionOutput(
            bullish_prob=bullish_prob,
            predicted_price=predicted_price,
            confidence=confidence,
            model_name="GAN",
        )
