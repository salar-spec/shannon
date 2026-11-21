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

# Shannon's container runs as a different, fixed user than this Codespace,
# so make sure it can write new files (deliverables/ reports) into the
# checkout, whether this is the first run or a re-run.
chmod -R a+rwX repos/juice-shop 2>/dev/null || true

# Shannon runs with --rm, so anything it writes outside repos/ or configs/
# (audit-logs/, sessions/) disappears with the container unless we mount it
# on the host too, and make sure the container's user can write into it.
# .shannon-store.json is NOT mounted: bind-mounting a single file breaks
# Shannon's atomic (write-then-rename/unlink) save of it, failing every
# run with "EBUSY: resource busy or locked". It's just orchestration
# bookkeeping, not needed for debugging, so let it live only in the
# container and disappear with it.
mkdir -p audit-logs sessions
chmod -R a+rwX audit-logs sessions 2>/dev/null || true

# Make sure the target is up.
if ! curl -fsS -o /dev/null http://localhost:3000; then
  docker start juice-shop >/dev/null 2>&1 || true
  sleep 10
fi

docker run --rm -it \
  --network host \
  --cap-add=NET_RAW --cap-add=NET_ADMIN \
  -e ANTHROPIC_API_KEY \
  -e GIT_CONFIG_COUNT=1 \
  -e GIT_CONFIG_KEY_0=safe.directory \
  -e GIT_CONFIG_VALUE_0="*" \
  -v "$(pwd)/repos:/app/repos" \
  -v "$(pwd)/configs:/app/configs" \
  -v "$(pwd)/audit-logs:/app/audit-logs" \
  -v "$(pwd)/sessions:/app/sessions" \
  shannon:latest \
  "http://localhost:3000" \
  "/app/repos/juice-shop" \
  --config /app/configs/example-config.yaml
