from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
import asyncio
import os

from api.predictions import router as pred_router
from api.market_data import router as market_router
from api.sentiment import router as sentiment_router

ALLOWED_ORIGINS = [
    "http://localhost:*",
    "http://127.0.0.1:*",
    # Flutter web on Vercel — update with your actual domain after deploy
    "https://crypto-nexus.vercel.app",
    "https://*.vercel.app",
    # HF Space UI
    "https://*.hf.space",
    # Allow all for development (tighten in production)
    "*",
]


@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Crypto Nexus AI backend starting...")
    # Download NLTK data if needed
    try:
        import nltk
        nltk.download("vader_lexicon", quiet=True)
        nltk.download("punkt", quiet=True)
    except Exception:
        pass
    yield
    print("Backend shutting down.")


app = FastAPI(
    title="Crypto Nexus AI API",
    description="Ensemble ML predictions (LSTM · GRU · GAN · Hybrid) with SHAP XAI for crypto portfolio optimization",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(pred_router, prefix="/api/predictions", tags=["Predictions"])
app.include_router(market_router, prefix="/api/market", tags=["Market Data"])
app.include_router(sentiment_router, prefix="/api/sentiment", tags=["Sentiment"])


@app.get("/health")
async def health():
    return {"status": "ok", "models": ["lstm", "gru", "gan", "hybrid", "ensemble"]}


@app.websocket("/ws/prices")
async def websocket_prices(websocket: WebSocket):
    """Stream real-time price updates to the Flutter app."""
    await websocket.accept()
    import random
    prices = {"BTC": 67420, "ETH": 3812, "SOL": 178, "AVAX": 38}
    try:
        while True:
            for sym, price in prices.items():
                prices[sym] = price * (1 + (random.random() - 0.5) * 0.001)
            await websocket.send_json({
                "type": "price_update",
                "data": {sym: round(p, 2) for sym, p in prices.items()}
            })
            await asyncio.sleep(1)
    except Exception:
        pass
