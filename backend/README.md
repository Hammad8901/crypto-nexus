---
title: Crypto Nexus Backend
emoji: 📈
colorFrom: blue
colorTo: purple
sdk: docker
pinned: false
app_port: 7860
---

# Crypto Nexus — AI Backend

FastAPI backend powering the Crypto Nexus app with ensemble ML predictions, XAI, and real-time sentiment.

## Live Endpoints
- `GET  /health` — service status
- `POST /api/predictions/ensemble` — LSTM · GRU · GAN · Hybrid ensemble + SHAP XAI
- `GET  /api/market/ohlcv/{symbol}` — live OHLCV candles (Binance)
- `GET  /api/sentiment/{symbol}` — multi-source news sentiment
- `WS   /ws/prices` — real-time price stream
- `GET  /docs` — Swagger UI (interactive API explorer)
