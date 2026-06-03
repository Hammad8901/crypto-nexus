#!/bin/bash
set -e

FLUTTER="$HOME/development/flutter/bin/flutter"
PROJECT="$HOME/Desktop/crypto_nexus"

echo ""
echo "═══════════════════════════════════════════════"
echo "   CRYPTO NEXUS — DEPLOY SCRIPT"
echo "═══════════════════════════════════════════════"
echo ""

# ── 1. Build Flutter web ─────────────────────────────────────────────────────
echo "[ 1/4 ] Building Flutter web app..."
cd "$PROJECT"
$FLUTTER build web --web-renderer canvaskit --release --dart-define=FLUTTER_WEB_USE_SKIA=true
echo "       Flutter web build complete → build/web/"
echo ""

# ── 2. Deploy Flutter web to Vercel ─────────────────────────────────────────
echo "[ 2/4 ] Deploying Flutter web to Vercel..."
if ! command -v vercel &> /dev/null; then
  echo "       Installing Vercel CLI..."
  npm install -g vercel
fi
cd "$PROJECT/build/web"
vercel --prod --yes
VERCEL_URL=$(vercel ls --scope=. 2>/dev/null | grep crypto-nexus | head -1 | awk '{print $2}' || echo "see Vercel dashboard")
echo "       Flutter web deployed!"
echo ""

# ── 3. Init git repo for backend ─────────────────────────────────────────────
echo "[ 3/4 ] Preparing backend for Hugging Face Spaces..."
cd "$PROJECT/backend"
if [ ! -d ".git" ]; then
  git init
  git checkout -b main
fi
git add .
git commit -m "Deploy Crypto Nexus AI backend" --allow-empty
echo "       Backend repo ready."
echo ""

# ── 4. Push to Hugging Face ───────────────────────────────────────────────────
echo "[ 4/4 ] Pushing to Hugging Face Spaces..."
echo ""
echo "  Run these commands (replace YOUR-HF-USERNAME):"
echo ""
echo "  cd $PROJECT/backend"
echo "  git remote add hf https://huggingface.co/spaces/YOUR-HF-USERNAME/crypto-nexus-backend"
echo "  git push hf main"
echo ""
echo "  Your backend will be live at:"
echo "  https://YOUR-HF-USERNAME-crypto-nexus-backend.hf.space"
echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════"
echo "   DEPLOYMENT COMPLETE"
echo "═══════════════════════════════════════════════"
echo ""
echo "  Flutter Web (Vercel):  https://crypto-nexus.vercel.app"
echo "  API Backend (HF):      https://YOUR-HF-USERNAME-crypto-nexus-backend.hf.space"
echo "  API Docs:              .../docs"
echo ""
echo "  Next step: Update lib/config/app_config.dart"
echo "  with your HF Space URL, then redeploy to Vercel."
echo ""
