#!/bin/bash
# Stop all infrastructure services (observability + core)
#
# Usage:
#   ./scripts/stop-all.sh          # Stop containers only
#   ./scripts/stop-all.sh -v       # Stop and remove volumes (data loss!)
#
# Stops observability stack first, then core infrastructure.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"

cd "$INFRA_DIR"

# Parse arguments
REMOVE_VOLUMES=""
if [[ "$1" == "-v" || "$1" == "--volumes" ]]; then
    REMOVE_VOLUMES="-v"
    echo "WARNING: Removing volumes will delete all persistent data!"
    read -p "Are you sure? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Aborted."
        exit 0
    fi
fi

echo "Stopping observability stack..."
docker compose -f docker-compose.observability.yml down $REMOVE_VOLUMES 2>/dev/null || echo "Observability stack not running or already stopped."

echo "Stopping core infrastructure..."
docker compose down $REMOVE_VOLUMES

echo ""
echo "All services stopped."
