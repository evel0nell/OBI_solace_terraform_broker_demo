#!/usr/bin/env bash
# start.sh — Boot the local Kafka cluster.
#
# Usage:
#   KAFKA_EXTERNAL_HOST=bore.pub KAFKA_EXTERNAL_PORT=46553 ./scripts/start.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

if [[ -z "${KAFKA_EXTERNAL_HOST:-}" ]] || [[ -z "${KAFKA_EXTERNAL_PORT:-}" ]]; then
  echo "ERROR: KAFKA_EXTERNAL_HOST and KAFKA_EXTERNAL_PORT must be set." >&2
  echo "       Run bore first, then:" >&2
  echo "       KAFKA_EXTERNAL_HOST=bore.pub KAFKA_EXTERNAL_PORT=<port> ./scripts/start.sh" >&2
  exit 1
fi

echo "==> Starting Kafka (external: ${KAFKA_EXTERNAL_HOST}:${KAFKA_EXTERNAL_PORT})..."
KAFKA_EXTERNAL_HOST="$KAFKA_EXTERNAL_HOST" \
KAFKA_EXTERNAL_PORT="$KAFKA_EXTERNAL_PORT" \
  docker compose up -d --force-recreate kafka

echo "==> Waiting for Kafka to become healthy..."
for i in $(seq 1 20); do
  STATUS=$(docker inspect --format='{{.State.Health.Status}}' kafka 2>/dev/null || echo "missing")
  if [[ "$STATUS" == "healthy" ]]; then
    echo "   Kafka is healthy."
    break
  fi
  echo "   attempt $i/20 — status=$STATUS, retrying in 5s..."
  sleep 5
done

# Create the demo topics (orders, payments) unless disabled.
if [[ "${KAFKA_CREATE_TOPICS:-true}" == "true" ]]; then
  echo "==> Creating demo topics..."
  "$SCRIPT_DIR/create-topics.sh"
fi

echo ""
echo "============================================================"
echo "  Kafka is up!"
echo ""
echo "  Bootstrap address (copy into terraform.tfvars):"
echo "    kafka_enabled           = true"
echo "    kafka_bootstrap_servers = \"${KAFKA_EXTERNAL_HOST}:${KAFKA_EXTERNAL_PORT}\""
echo "============================================================"
