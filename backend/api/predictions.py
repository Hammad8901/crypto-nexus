from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from models.ensemble import EnsembleModel

router = APIRouter()
_ensemble_cache: dict[str, EnsembleModel] = {}


class OhlcvCandle(BaseModel):
    time: int
    open: float
    high: float
    low: float
    close: float
    volume: float


class PredictRequest(BaseModel):
    symbol: str
    candles: list[OhlcvCandle]


def _get_ensemble(symbol: str) -> EnsembleModel:
    if symbol not in _ensemble_cache:
        _ensemble_cache[symbol] = EnsembleModel(symbol)
    return _ensemble_cache[symbol]


@router.post("/ensemble")
async def predict_ensemble(req: PredictRequest):
    """Run ensemble prediction for a given symbol with provided OHLCV data."""
    if len(req.candles) < 30:
        raise HTTPException(400, "Need at least 30 candles for prediction")

    ohlcv = [c.model_dump() for c in req.candles]
    model = _get_ensemble(req.symbol)
    result = model.predict(ohlcv)

    return {
        "symbol": result.symbol,
        "bullish_probability": result.bullish_probability,
        "predicted_price": result.predicted_price,
        "price_change_percent": result.price_change_percent,
        "signal": result.signal,
        "confidence": result.confidence,
        "model_weights": result.model_weights,
        "model_predictions": [
            {
                "model_name": p.model_name,
                "bullish_prob": p.bullish_prob,
                "predicted_price": p.predicted_price,
                "confidence": p.confidence,
            }
            for p in result.model_predictions
        ],
        "xai": {
            "summary": result.xai.summary,
            "features": [
                {
                    "name": f.name,
                    "impact": f.impact,
                    "is_positive": f.is_positive,
                }
                for f in result.xai.features
            ],
        },
    }


@router.get("/symbols")
async def supported_symbols():
    return {"symbols": ["BTC", "ETH", "SOL", "AVAX", "BNB", "XRP", "ADA", "DOT"]}
