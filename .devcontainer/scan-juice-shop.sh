#!/usr/bin/env bash
# Run Shannon against the local Juice Shop practice target.
# Only point Shannon at systems you own or have written permission to test.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "ANTHROPIC_API_KEY is not set." >&2
  echo "Add it at https://github.com/settings/codespaces (New secret, repo access: this repo)," >&2
  echo "then restart this Codespace." >&2
  exit 1
fi

# Make sure the target is up.
if ! curl -fsS -o /dev/null http://localhost:3000; then
  docker start juice-shop >/dev/null 2>&1 || true
  sleep 10
fi

docker run --rm -it \
  --network host \
  --cap-add=NET_RAW --cap-add=NET_ADMIN \
  -e ANTHROPIC_API_KEY \
  -v "$(pwd)/repos:/app/repos" \
  -v "$(pwd)/configs:/app/configs" \
  shannon:latest \
  "http://localhost:3000" \
  "/app/repos/juice-shop" \
  --config /app/configs/example-config.yaml
