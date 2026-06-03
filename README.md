# Crypto Nexus — AI-Powered Portfolio Intelligence

A production-grade Flutter + Python mobile app combining ensemble ML, explainable AI (XAI), and real-time news sentiment analysis for crypto portfolio optimization.

---

## Is it running locally or deployed?

**100% LOCAL — nothing is deployed to any cloud or server.**

| Component | Where it runs |
|---|---|
| Flutter app | Your Android/iOS phone (via USB or Wi-Fi) |
| Python backend | Your Mac at `localhost:8000` |
| ML models (LSTM/GRU/GAN/Ensemble) | Your Mac CPU/GPU |
| Live market data | Fetched from Binance public API |
| News sentiment | Fetched and processed on your Mac |

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    YOUR ANDROID PHONE                         │
│  ┌────────────────────────────────────────────────────────┐  │
│  │              Flutter App (Dart)                         │  │
│  │  Splash → Portfolio → Markets → AI Oracle → News       │  │
│  │  Custom Candlestick Chart + XAI Hover Tooltip          │  │
│  └─────────────────────┬──────────────────────────────────┘  │
└────────────────────────│──────────────────────────────────────┘
                         │ HTTP REST + WebSocket
┌────────────────────────▼──────────────────────────────────────┐
│                  YOUR MAC (localhost:8000)                      │
│                                                                │
│  FastAPI Backend                                               │
│  ├── POST /api/predictions/ensemble  ← ML predictions          │
│  ├── GET  /api/market/ohlcv/{sym}    ← Binance live candles    │
│  ├── GET  /api/sentiment/{sym}       ← NLP sentiment           │
│  └── WS   /ws/prices                ← Real-time price stream   │
│                                                                │
│  ML Model Layer                                                │
│  ├── LSTM   (3-layer, 128 units, seq=60)                       │
│  ├── GRU    (Bidirectional, 256 units, seq=48)                 │
│  ├── GAN    (Monte Carlo, 100 scenarios)                       │
│  ├── Hybrid (CNN + LSTM, multi-timeframe)                      │
│  └── Ensemble ──► XAI (SHAP feature attribution)               │
│                                                                │
│  Sentiment Layer                                               │
│  └── FinBERT + VADER ← Reuters, Bloomberg, CoinDesk, Reddit   │
└────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

### Flutter (Mobile App)
| Package | Purpose |
|---|---|
| `flutter_animate` | Entrance animations, scroll effects |
| `fl_chart` | Chart infrastructure |
| Custom `CustomPainter` | Candlestick rendering + XAI overlay |
| `glassmorphism` | Frosted glass card effects |
| `shimmer` | Loading skeleton states |
| `flutter_riverpod` | Reactive state management |
| `web_socket_channel` | Real-time price WebSocket |
| `dio` | HTTP calls to Python backend |

### Python (Backend + ML)
| Library | Purpose |
|---|---|
| `FastAPI` | REST API + WebSocket |
| `TensorFlow 2.16` | LSTM + GRU training & inference |
| `PyTorch` | GAN model |
| `scikit-learn` | Feature scaling, ensemble weighting |
| `shap` | Explainable AI (SHAP values) |
| `transformers` (FinBERT) | Financial domain NLP sentiment |
| `vaderSentiment` | Fallback rule-based sentiment |
| `ccxt` | Binance market data |

---

## Project Structure

```
crypto_nexus/
├── lib/                              Flutter app
│   ├── main.dart                     App entry point
│   ├── theme/app_theme.dart          Dark theme + color palette
│   ├── models/
│   │   ├── candle_data.dart          CandleData, XaiExplanation, ModelPrediction
│   │   └── crypto_asset.dart         CryptoAsset, SentimentData, EnsembleResult
│   ├── data/mock_data.dart           Mock data (replace with live API calls)
│   ├── screens/
│   │   ├── splash_screen.dart        Animated intro — orbiting particles
│   │   ├── main_nav_screen.dart      Bottom nav shell (4 tabs)
│   │   ├── portfolio_screen.dart     Holdings, total P&L, allocation bar
│   │   ├── markets_screen.dart       Price list + sparkline mini-charts
│   │   ├── crypto_detail_screen.dart Candlestick chart + AI/Sentiment/News tabs
│   │   ├── ai_oracle_screen.dart     Model architecture + ensemble verdicts
│   │   └── news_screen.dart          Sentiment feed + source filter
│   └── widgets/
│       ├── candlestick_chart.dart    Custom chart painter + XAI tooltip
│       ├── crypto_card.dart          Portfolio holding card (animated)
│       ├── model_prediction_card.dart LSTM/GRU/GAN/Hybrid + Ensemble cards
│       └── sentiment_gauge.dart      Semicircular gauge + news cards
│
├── backend/                          Python ML backend
│   ├── main.py                       FastAPI + WebSocket server
│   ├── requirements.txt              All Python dependencies
│   ├── models/
│   │   ├── lstm_model.py             3-layer stacked LSTM
│   │   ├── gru_model.py              Bidirectional GRU
│   │   ├── gan_model.py              Monte Carlo GAN
│   │   └── ensemble.py               Weighted ensemble + SHAP XAI
│   ├── services/
│   │   └── sentiment_service.py      FinBERT + VADER multi-source NLP
│   └── api/
│       ├── predictions.py            POST /api/predictions/ensemble
│       ├── market_data.py            GET  /api/market/ohlcv/{symbol}
│       └── sentiment.py              GET  /api/sentiment/{symbol}
│
└── assets/images/ animations/ icons/
```

---

## ML Models — Full Detail

### LSTM (Long Short-Term Memory)
```
Input (60 candles × 6 features)
  ↓  [Close, Volume, RSI-14, MACD, BB-Upper, BB-Lower]
LSTM(128, return_seq=True) + Dropout(0.2)
  ↓
LSTM(128, return_seq=True) + Dropout(0.2)
  ↓
LSTM(64) + Dropout(0.2)
  ↓
Dense(32, relu)
  ↓
├── Dense(1)           → Predicted price
└── Dense(1, sigmoid)  → Bullish probability (0–1)
```
**Strength:** Long-range temporal dependencies, trend persistence patterns.

### GRU (Gated Recurrent Unit)
```
Input (48 candles × 6 features)
  ↓
Bidirectional GRU(256) + Dropout(0.2)
  ↓
GRU(128) + Dropout(0.2)
  ↓
Dense(64, relu) + Dropout(0.15)
  ↓
├── Dense(1)           → Predicted price
└── Dense(1, sigmoid)  → Bullish probability
```
**Strength:** Faster than LSTM, better at short-term momentum and volume spikes.

### GAN (Generative Adversarial Network)
```
Generator:  Noise(64) + Market State → 10-step price path
Discriminator: Real vs Synthetic price sequences

Inference mode:
  → Generate 100 Monte Carlo price paths
  → % of paths ending above current price = Bullish probability
```
**Strength:** Models non-linear regime changes, fat-tail risk events.

### Hybrid CNN + LSTM
```
Multi-timeframe input (1H + 4H + 1D candles)
  ↓
CNN feature extractor (pattern recognition)
  ↓
LSTM temporal layer
  ↓
Ensemble output
```
**Strength:** Recognizes patterns across multiple timeframes simultaneously.

### Ensemble Weighting
```
Final signal = Σ (model_i × weight_i)

Weights start at: LSTM=30%, GRU=25%, GAN=20%, Hybrid=25%
Weights updated every 30 days based on rolling accuracy.

Signal thresholds:
  Bullish ≥ 0.75 AND Confidence ≥ 0.80  →  STRONG BUY
  Bullish ≥ 0.60                          →  BUY
  0.40 < Bullish < 0.60                   →  HOLD
  Bullish ≤ 0.40                          →  SELL
  Bullish ≤ 0.25 AND Confidence ≥ 0.80   →  STRONG SELL
```

---

## XAI — Explainable AI

Tap any candle on the chart to see **why** the price moved:

```
┌──────────────────────────────────────────┐
│  BTC · Nov 23, 14:00   │   +2.87%  ▲   │
├──────────────────────────────────────────┤
│  Open  $67,200  │  High  $67,890        │
│  Low   $66,940  │  Close $67,420        │
├──────────────────────────────────────────┤
│  🤖 AI MODEL SIGNALS                     │
│  LSTM    ████████░░  82% BULLISH         │
│  GRU     ███████░░░  71% BULLISH         │
│  GAN     ████████░░  78% BULLISH         │
│  Hybrid  █████████░  86% BULLISH         │
├──────────────────────────────────────────┤
│  📊 XAI FEATURE IMPACT (SHAP-style)      │
│  News Sentiment   █████░   +3.1%         │
│  RSI Signal       ████░░   +2.3%         │
│  Volume Spike     ███░░░   +1.8%         │
│  MACD Crossover   ██░░░░   +1.5%         │
│  BTC Dominance    █░░░░░   +0.9%         │
├──────────────────────────────────────────┤
│  📰 TRIGGERING EVENT                     │
│  "BlackRock ETF sees $500M inflow"       │
│  Reuters   │   Sentiment Score: +0.92    │
└──────────────────────────────────────────┘
```

SHAP (SHapley Additive exPlanations) values show the marginal contribution of each feature to the model's prediction. Positive = pushed price up. Negative = pushed price down.

---

## News Sentiment Sources

| Source | Type | Weight |
|---|---|---|
| Reuters | Financial news | High |
| Bloomberg | Financial news | High |
| CoinDesk | Crypto news | Medium |
| The Block | Crypto research | Medium |
| CoinTelegraph | Crypto news | Medium |
| Decrypt | Crypto news | Medium |
| Reddit (r/Bitcoin, r/CryptoCurrency) | Community | Low |
| Twitter/X | Social signal | Low |

**NLP pipeline:**
1. Fetch articles from all sources
2. Run through **FinBERT** (ProsusAI/finbert) — 3-class financial sentiment
3. Aggregate scores weighted by source credibility
4. Generate overall score (−1 bearish → +1 bullish)

---

## How to Run on Your Android Phone

### Step 1 — Complete Android SDK Setup
Open **Android Studio** app → go through the Setup Wizard → downloads SDK (~2GB)

Then configure Flutter:
```bash
export PATH="$HOME/development/flutter/bin:$PATH"
flutter config --android-sdk ~/Library/Android/sdk
flutter doctor    # verify Android toolchain is green
```

### Step 2 — Enable USB Debugging on Phone
```
Settings → About Phone → tap Build Number 7 times
→ Back → Developer Options → USB Debugging: ON
```
Connect USB cable → tap **Allow** on the phone popup.

### Step 3 — Run the App
```bash
export PATH="$HOME/development/flutter/bin:$PATH"
cd ~/Desktop/crypto_nexus
flutter devices           # your phone should appear
flutter run               # builds and installs (first time ~3 min)
```

Hot reload after changes: press **r** in terminal
Hot restart: press **R**
Quit: press **q**

### Step 4 — Start Python Backend (for live data)
```bash
cd ~/Desktop/crypto_nexus/backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Interactive API docs → open in browser: **http://localhost:8000/docs**

---

## API Reference

### POST /api/predictions/ensemble
```json
Request:
{
  "symbol": "BTC",
  "candles": [
    { "time": 1717200000, "open": 67200, "high": 67890,
      "low": 66940, "close": 67420, "volume": 2341.5 }
  ]
}

Response:
{
  "symbol": "BTC",
  "bullish_probability": 0.81,
  "predicted_price": 71200.50,
  "price_change_percent": 5.6,
  "signal": "STRONG BUY",
  "confidence": 0.87,
  "model_weights": { "LSTM": 0.30, "GRU": 0.25, "GAN": 0.20, "Hybrid": 0.25 },
  "model_predictions": [ ... ],
  "xai": {
    "summary": "Bullish momentum driven by news sentiment",
    "features": [
      { "name": "News Sentiment", "impact": 3.1, "is_positive": true },
      ...
    ]
  }
}
```

### GET /api/market/ohlcv/{symbol}?timeframe=4h&limit=100
Returns live OHLCV candles from Binance (no API key required for public data).

### GET /api/sentiment/{symbol}
Returns overall score, positive/negative/neutral counts, and recent articles.

### WebSocket ws://localhost:8000/ws/prices
```json
Streams every 1 second:
{ "type": "price_update", "data": { "BTC": 67421.50, "ETH": 3813.20 } }
```

---

## Connecting Flutter to Live Backend

When running Flutter on a physical phone, use your Mac's local IP instead of `localhost`:

```bash
# Find your Mac's IP
ipconfig getifaddr en0
```

Then update the base URL in your API service:
```dart
// lib/services/api_service.dart (to be created)
const backendUrl = 'http://192.168.1.x:8000';  // your Mac's IP
```

---

## Roadmap

- [ ] **Live data** — connect Flutter to real Binance WebSocket prices
- [ ] **Unity 3D** — embed 3D coin viewer via flutter_unity_widget (once Xcode 14.3.1 finishes downloading)
- [ ] **Train models** — train LSTM/GRU on 4 years of historical BTC/ETH OHLCV data
- [ ] **On-device ML** — export trained models to TensorFlow Lite for offline inference
- [ ] **Push alerts** — notify when ensemble signal changes (BUY/SELL)
- [ ] **Paper trading** — simulate portfolio based on AI signals
- [ ] **More assets** — add BNB, XRP, ADA, DOT, MATIC

---

## Color Palette

| Name | Hex | Used for |
|---|---|---|
| Background | `#050508` | App background |
| Card | `#0D0D14` | Cards and surfaces |
| Primary (Cyan) | `#00D4FF` | Primary accent, LSTM |
| Secondary (Purple) | `#7C3AED` | Secondary accent, GRU |
| Accent (Orange) | `#FF6B35` | Warnings, GAN, news events |
| Positive (Green) | `#00FF88` | Bullish, profit |
| Negative (Red-pink) | `#FF3366` | Bearish, loss |
| Neutral (Gold) | `#FFAA00` | Hold signals |
