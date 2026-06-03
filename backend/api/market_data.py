from fastapi import APIRouter, Query
import ccxt.async_support as ccxt
from datetime import datetime

router = APIRouter()


@router.get("/ohlcv/{symbol}")
async def get_ohlcv(
    symbol: str,
    timeframe: str = Query("4h", pattern="^(1m|5m|15m|1h|4h|1d|1w)$"),
    limit: int = Query(100, ge=10, le=500),
):
    """Fetch OHLCV from Binance (no API key needed for public data)."""
    try:
        exchange = ccxt.binance()
        ohlcv = await exchange.fetch_ohlcv(f"{symbol}/USDT", timeframe, limit=limit)
        await exchange.close()
        return {
            "symbol": symbol,
            "timeframe": timeframe,
            "candles": [
                {
                    "time": int(c[0]),
                    "open": c[1], "high": c[2], "low": c[3],
                    "close": c[4], "volume": c[5],
                }
                for c in ohlcv
            ],
        }
    except Exception as e:
        return {"error": str(e), "candles": []}


@router.get("/ticker/{symbol}")
async def get_ticker(symbol: str):
    """Get current price and 24h stats."""
    try:
        exchange = ccxt.binance()
        ticker = await exchange.fetch_ticker(f"{symbol}/USDT")
        await exchange.close()
        return {
            "symbol": symbol,
            "price": ticker["last"],
            "change_24h": ticker["change"],
            "change_percent_24h": ticker["percentage"],
            "volume_24h": ticker["quoteVolume"],
            "high_24h": ticker["high"],
            "low_24h": ticker["low"],
        }
    except Exception as e:
        return {"error": str(e)}
