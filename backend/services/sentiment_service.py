"""
Multi-source sentiment aggregation.
Sources: Reuters, Bloomberg, CoinDesk, The Block, CoinTelegraph,
         Reddit (r/CryptoCurrency, r/Bitcoin), Twitter/X, Decrypt.
Uses FinBERT for financial domain NLP + VADER as fallback.
"""

import re
from dataclasses import dataclass
from datetime import datetime


@dataclass
class ArticleSentiment:
    headline: str
    source: str
    url: str
    sentiment_score: float  # -1 to +1
    magnitude: float        # 0 to 1 (confidence)
    published_at: datetime
    symbol: str


@dataclass
class AggregatedSentiment:
    symbol: str
    overall_score: float
    positive_count: int
    negative_count: int
    neutral_count: int
    label: str
    articles: list[ArticleSentiment]


class SentimentService:
    SOURCES = [
        "Reuters", "Bloomberg", "CoinDesk", "The Block",
        "CoinTelegraph", "Decrypt", "Benzinga", "Forbes Crypto",
    ]

    def __init__(self):
        self.finbert = None
        self._load_model()

    def _load_model(self):
        """Load FinBERT for financial sentiment analysis."""
        try:
            from transformers import pipeline
            self.finbert = pipeline(
                "sentiment-analysis",
                model="ProsusAI/finbert",
                return_all_scores=True,
            )
        except Exception:
            # Fallback to VADER
            self.finbert = None

    def analyze_text(self, text: str) -> tuple[float, float]:
        """Returns (score, magnitude) where score ∈ [-1, +1]."""
        if self.finbert:
            results = self.finbert(text[:512])[0]
            scores = {r["label"]: r["score"] for r in results}
            score = scores.get("positive", 0) - scores.get("negative", 0)
            magnitude = max(scores.values())
            return float(score), float(magnitude)

        # VADER fallback
        try:
            from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
            analyzer = SentimentIntensityAnalyzer()
            compound = analyzer.polarity_scores(text)["compound"]
            return float(compound), float(abs(compound))
        except Exception:
            return 0.0, 0.5

    def scrape_and_analyze(self, symbol: str) -> AggregatedSentiment:
        """
        Fetch and analyze recent news for a given crypto symbol.
        In production: use CryptoPanic API, NewsAPI, Reddit PRAW, Twitter v2 API.
        """
        # Placeholder — real impl would scrape live sources
        articles = self._mock_articles(symbol)

        scores = [a.sentiment_score for a in articles]
        overall = sum(scores) / len(scores) if scores else 0.0

        positive = sum(1 for s in scores if s > 0.2)
        negative = sum(1 for s in scores if s < -0.2)
        neutral = len(scores) - positive - negative

        return AggregatedSentiment(
            symbol=symbol,
            overall_score=round(overall, 4),
            positive_count=positive,
            negative_count=negative,
            neutral_count=neutral,
            label=self._label(overall),
            articles=articles,
        )

    def _label(self, score: float) -> str:
        if score > 0.6: return "Extremely Bullish"
        if score > 0.3: return "Very Bullish"
        if score > 0.1: return "Slightly Bullish"
        if score > -0.1: return "Neutral"
        if score > -0.3: return "Slightly Bearish"
        if score > -0.6: return "Bearish"
        return "Extremely Bearish"

    def _mock_articles(self, symbol: str) -> list[ArticleSentiment]:
        import random
        from datetime import timedelta
        now = datetime.now()
        return [
            ArticleSentiment(
                headline=f"{symbol} shows strong institutional demand",
                source="Reuters",
                url="",
                sentiment_score=round(random.uniform(0.4, 0.9), 3),
                magnitude=round(random.uniform(0.6, 0.95), 3),
                published_at=now - timedelta(hours=random.randint(1, 12)),
                symbol=symbol,
            )
            for _ in range(8)
        ]
