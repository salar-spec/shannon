#!/usr/bin/env bash
# One-time setup for a Codespace: build the Shannon image, fetch the Juice
# Shop practice target (source + running app).
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Building the Shannon image (several minutes)..."
docker build -t shannon:latest .

echo "==> Fetching Juice Shop source into repos/juice-shop..."
if [ ! -d repos/juice-shop ]; then
  git clone --depth 1 https://github.com/juice-shop/juice-shop repos/juice-shop
fi

echo "==> Starting Juice Shop on port 3000..."
docker rm -f juice-shop >/dev/null 2>&1 || true
docker run -d --name juice-shop --restart unless-stopped -p 3000:3000 bkimminich/juice-shop

echo
echo "Setup done. Save ANTHROPIC_API_KEY as a Codespaces secret, then run:"
echo "  bash .devcontainer/scan-juice-shop.sh"
