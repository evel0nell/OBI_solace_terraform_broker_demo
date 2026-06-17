#!/usr/bin/env bash
# create-topics.sh — Create the demo Kafka topics used by the Solace Kafka bridge.
#
# Topics (3 partitions each so the partition/offset substitution examples are
# meaningful): orders, payments
#
# Usage:
#   ./scripts/create-topics.sh                 # uses defaults below
#   KAFKA_PARTITIONS=6 ./scripts/create-topics.sh

set -euo pipefail

CONTAINER="${KAFKA_CONTAINER:-kafka}"
BOOTSTRAP="${KAFKA_BOOTSTRAP:-localhost:9092}"   # in-container PLAINTEXT listener
PARTITIONS="${KAFKA_PARTITIONS:-3}"
REPLICATION="${KAFKA_REPLICATION:-1}"
TOPICS=(orders payments)

for topic in "${TOPICS[@]}"; do
  echo "==> Creating topic '${topic}' (partitions=${PARTITIONS}, rf=${REPLICATION})..."
  docker exec "$CONTAINER" kafka-topics \
    --bootstrap-server "$BOOTSTRAP" \
    --create --if-not-exists \
    --topic "$topic" \
    --partitions "$PARTITIONS" \
    --replication-factor "$REPLICATION"
done

echo ""
echo "==> Current topics:"
docker exec "$CONTAINER" kafka-topics --bootstrap-server "$BOOTSTRAP" --list
