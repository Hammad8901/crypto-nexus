from fastapi import APIRouter
from services.sentiment_service import SentimentService

router = APIRouter()
_service = SentimentService()


@router.get("/{symbol}")
async def get_sentiment(symbol: str):
    result = _service.scrape_and_analyze(symbol.upper())
    return {
        "symbol": result.symbol,
        "overall_score": result.overall_score,
        "positive_count": result.positive_count,
        "negative_count": result.negative_count,
        "neutral_count": result.neutral_count,
        "label": result.label,
        "articles": [
            {
                "headline": a.headline,
                "source": a.source,
                "sentiment_score": a.sentiment_score,
                "magnitude": a.magnitude,
                "published_at": a.published_at.isoformat(),
            }
            for a in result.articles[:10]
        ],
    }
