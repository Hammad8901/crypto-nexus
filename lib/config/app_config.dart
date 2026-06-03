import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  // ── Hugging Face Spaces backend URL ────────────────────────────────────────
  // After deploying to HF Spaces, replace with your actual Space URL:
  // https://YOUR-USERNAME-crypto-nexus-backend.hf.space
  static const _hfBackendUrl = 'https://hammadahmed0566-crypto-nexus-backend.hf.space';

  // ── Local dev backend ───────────────────────────────────────────────────────
  static const _localBackendUrl = 'http://localhost:8000';

  /// Base REST URL. Uses localhost in debug, HF Spaces in release.
  static String get backendUrl {
    if (kReleaseMode) return _hfBackendUrl;
    if (kIsWeb) return _localBackendUrl;
    // On a physical device, use Mac's LAN IP instead of localhost
    return _localBackendUrl;
  }

  /// WebSocket URL (wss in production, ws locally).
  static String get wsUrl {
    if (kReleaseMode) {
      return _hfBackendUrl.replaceFirst('https://', 'wss://') + '/ws/prices';
    }
    return 'ws://localhost:8000/ws/prices';
  }

  // ── External APIs (no key required) ────────────────────────────────────────
  static const coinGeckoBase = 'https://api.coingecko.com/api/v3';
  static const binanceRestBase = 'https://api.binance.com/api/v3';
  static const binanceWsBase = 'wss://stream.binance.com:9443/stream';

  // ── App metadata ────────────────────────────────────────────────────────────
  static const appName = 'Crypto Nexus';
  static const appVersion = '1.0.0';
}
