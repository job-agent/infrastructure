#!/bin/bash
# Start all infrastructure services (core + observability)
#
# Usage:
#   ./scripts/start-all.sh
#
# This script starts core infrastructure first, waits for services to be healthy,
# then starts the observability stack.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"

cd "$INFRA_DIR"

echo "Starting core infrastructure..."
docker compose up -d

echo "Waiting for core services to be healthy..."

# Function to check if a container is healthy using docker inspect
# This is more reliable than grep on docker compose ps output
check_healthy() {
    local container_name="$1"
    local status
    status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null)
    [ "$status" = "healthy" ]
}

# Wait for postgres to be healthy (required for postgres-exporter)
timeout=60
elapsed=0
while ! check_healthy "job-agent-db"; do
    if [ $elapsed -ge $timeout ]; then
        echo "Timeout waiting for postgres to be healthy"
        exit 1
    fi
    sleep 2
    elapsed=$((elapsed + 2))
done
echo "PostgreSQL is healthy."

# Wait for rabbitmq to be healthy (required for prometheus scraping)
elapsed=0
while ! check_healthy "job-agent-rabbitmq"; do
    if [ $elapsed -ge $timeout ]; then
        echo "Timeout waiting for rabbitmq to be healthy"
        exit 1
    fi
    sleep 2
    elapsed=$((elapsed + 2))
done
echo "RabbitMQ is healthy."

echo "Starting observability stack..."
docker compose -f docker-compose.observability.yml up -d

echo ""
echo "All services started successfully!"
echo ""
echo "Core Infrastructure:"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "Observability Stack:"
docker compose -f docker-compose.observability.yml ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "Grafana UI: http://localhost:${GRAFANA_PORT:-3002}"
echo "RabbitMQ Management: http://localhost:${RABBITMQ_MANAGEMENT_PORT:-15672}"
