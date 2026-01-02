# Infrastructure

Shared infrastructure services for the Job Agent platform.

## Architecture

The infrastructure is split into two compose files:

- **`docker-compose.yml`** - Core infrastructure (required for application operation)
- **`docker-compose.observability.yml`** - Observability stack (monitoring, logging, tracing)

## Core Infrastructure Services

| Service | Container Name | Internal Port | Host Port |
|---------|----------------|---------------|-----------|
| PostgreSQL (pgvector) | job-agent-db | 5432 | ${POSTGRES_PORT} |
| RabbitMQ | job-agent-rabbitmq | 5672, 15672 | ${RABBITMQ_PORT}, ${RABBITMQ_MANAGEMENT_PORT} |
| Ollama | job-agent-ollama | 11434 | 11434 |

## Observability Stack Services

| Service | Container Name | Internal Port | Host Port |
|---------|----------------|---------------|-----------|
| MinIO (Object Storage) | minio | 9000, 9001 | ${MINIO_PORT}, ${MINIO_CONSOLE_PORT} |
| Tempo (Tracing) | tempo | 3200 | ${TEMPO_PORT} |
| Loki (Logs) | loki | 3100 | (internal only) |
| OTel Collector | otel-collector | 4317 | 4317 |
| Grafana (Dashboard) | grafana | 3000 | ${GRAFANA_PORT} |
| Prometheus (Metrics) | prometheus | 9090 | (internal only) |
| postgres-exporter | postgres-exporter | 9187 | (internal only) |
| cAdvisor | cadvisor | 8080 | (internal only) |

## Prerequisites

- Docker
- Docker Compose

## Setup

1. Copy the environment template:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and configure values as needed (defaults work for local development).

3. Choose your startup option:

### Option A: Core Infrastructure Only (Lightweight Development)

Start only the essential services (PostgreSQL, RabbitMQ, Ollama):

```bash
docker compose up -d
docker compose ps
```

This is ideal when you do not need monitoring/tracing capabilities.

### Option B: Full Stack with Convenience Script

Start both core infrastructure and observability:

```bash
./scripts/start-all.sh
```

### Option C: Manual Full Stack

Start core infrastructure first, then observability:

```bash
docker compose up -d
docker compose -f docker-compose.observability.yml up -d
```

## Startup Order

**Important:** The startup order must be followed:

1. Core infrastructure (`docker-compose.yml`) must start first
2. Observability stack (`docker-compose.observability.yml`) connects to the existing network

If you start observability without core infrastructure, you will see a network error:
```
network job-agent-network declared as external, but could not be found
```

For application services (telegram_bot, scrappers), start infrastructure first:

```bash
# 1. Start infrastructure
cd infrastructure
docker compose up -d
# Optionally: docker compose -f docker-compose.observability.yml up -d

# 2. Wait for services to be healthy
docker compose ps

# 3. Start application services (from another terminal)
cd ../job-agent-platform
docker compose up -d telegram_bot
```

## Usage Scenarios

### Development Without Observability

For lightweight development when you do not need metrics, traces, or logs:

```bash
cd infrastructure
docker compose up -d
```

Resource savings: Skips 8 containers (MinIO, Tempo, Loki, OTel Collector, Grafana, Prometheus, exporters).

### Full Local Development

For debugging, performance analysis, or testing the observability pipeline:

```bash
cd infrastructure
./scripts/start-all.sh
```

Access Grafana at `http://localhost:3002` for dashboards.

### Production Considerations

In production environments, you may want to:
- Use external managed services (AWS RDS, CloudAMQP, etc.)
- Deploy observability tools separately (Grafana Cloud, Datadog, etc.)
- Customize resource limits and retention policies
- Use separate `.env` files per environment

## Service Endpoints

### Internal (Docker network)

Services on the `job-agent-network` can connect using container names:

- **PostgreSQL**: `postgres:5432` or `job-agent-db:5432`
- **RabbitMQ AMQP**: `rabbitmq:5672` or `job-agent-rabbitmq:5672`
- **Ollama**: `ollama:11434` or `job-agent-ollama:11434`
- **Tempo**: `tempo:3200`
- **Loki**: `loki:3100`
- **OTel Collector**: `otel-collector:4317`

### External (Host machine)

For local development tools:

- **PostgreSQL**: `localhost:${POSTGRES_PORT}` (default: 5432)
- **RabbitMQ AMQP**: `localhost:${RABBITMQ_PORT}` (default: 5672)
- **RabbitMQ Management UI**: `http://localhost:${RABBITMQ_MANAGEMENT_PORT}` (default: 15672)
- **Ollama API**: `http://localhost:11434`
- **Grafana**: `http://localhost:${GRAFANA_PORT}` (default: 3002)
- **MinIO Console**: `http://localhost:${MINIO_CONSOLE_PORT}` (default: 9001)
- **Tempo API**: `http://localhost:${TEMPO_PORT}` (default: 3200)

## Network

The core infrastructure compose file creates and owns the `job-agent-network` bridge network.
All other services (observability stack, application services) connect to this network as external.

## Commands

### Core Infrastructure

```bash
# Start core services
docker compose up -d

# Stop core services
docker compose down

# View core logs
docker compose logs -f

# View specific service logs
docker compose logs -f postgres

# Check service health
docker compose ps

# Restart a service
docker compose restart rabbitmq
```

### Observability Stack

```bash
# Start observability (requires core infrastructure running)
docker compose -f docker-compose.observability.yml up -d

# Stop observability
docker compose -f docker-compose.observability.yml down

# View observability logs
docker compose -f docker-compose.observability.yml logs -f

# Check observability status
docker compose -f docker-compose.observability.yml ps
```

### Convenience Scripts

```bash
# Start everything (core + observability)
./scripts/start-all.sh

# Stop everything
./scripts/stop-all.sh

# Stop everything and remove volumes (data loss!)
./scripts/stop-all.sh -v
```

## Troubleshooting

### Services not starting

Check logs for errors:
```bash
docker compose logs
docker compose -f docker-compose.observability.yml logs
```

### Network not found by observability stack

Ensure core infrastructure is started first:
```bash
docker compose up -d
docker network ls | grep job-agent-network
```

### Network not found by application services

Ensure infrastructure is started first:
```bash
docker compose up -d
docker network ls | grep job-agent-network
```

### PostgreSQL connection refused

Wait for health check to pass:
```bash
docker compose ps  # postgres should show "healthy"
```

### RabbitMQ connection issues

Check RabbitMQ is accepting connections:
```bash
docker compose exec rabbitmq rabbitmq-diagnostics -q ping
```

### postgres-exporter connection errors

If postgres-exporter logs show connection errors, ensure PostgreSQL is healthy.
The exporter will automatically retry until PostgreSQL is available.

### Grafana shows "No data"

1. Verify observability stack is running: `docker compose -f docker-compose.observability.yml ps`
2. Check if core infrastructure is healthy: `docker compose ps`
3. Wait a few minutes for metrics to be collected
4. Check Prometheus targets at Grafana > Explore > Prometheus

### Tempo/Loki storage errors

Verify MinIO is healthy and buckets were created:
```bash
docker compose -f docker-compose.observability.yml logs minio-init
```
