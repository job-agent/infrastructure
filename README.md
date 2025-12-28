# Infrastructure

Shared infrastructure services for the Job Agent platform.

## Services

| Service | Container Name | Internal Port | Host Port |
|---------|----------------|---------------|-----------|
| PostgreSQL (pgvector) | job-agent-db | 5432 | ${POSTGRES_PORT} |
| RabbitMQ | job-agent-rabbitmq | 5672, 15672 | ${RABBITMQ_PORT}, ${RABBITMQ_MANAGEMENT_PORT} |
| Ollama | job-agent-ollama | 11434 | 11434 |

## Prerequisites

- Docker
- Docker Compose

## Setup

1. Copy the environment template:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and configure values as needed (defaults work for local development).

3. Start infrastructure:
   ```bash
   docker compose up -d
   ```

4. Verify services are healthy:
   ```bash
   docker compose ps
   ```

## Startup Order

**Infrastructure MUST be started before any application services.**

```bash
# 1. Start infrastructure
cd infrastructure
docker compose up -d

# 2. Wait for services to be healthy
docker compose ps

# 3. Start application services (from another terminal)
cd ../job-agent-platform
docker compose up -d telegram_bot
```

## Service Endpoints

### Internal (Docker network)

Services on the `job-agent-network` can connect using container names:

- **PostgreSQL**: `postgres:5432` or `job-agent-db:5432`
- **RabbitMQ AMQP**: `rabbitmq:5672` or `job-agent-rabbitmq:5672`
- **Ollama**: `ollama:11434` or `job-agent-ollama:11434`

### External (Host machine)

For local development tools (DBeaver, pgAdmin, etc.):

- **PostgreSQL**: `localhost:${POSTGRES_PORT}` (default: 5432)
- **RabbitMQ AMQP**: `localhost:${RABBITMQ_PORT}` (default: 5672)
- **RabbitMQ Management UI**: `http://localhost:${RABBITMQ_MANAGEMENT_PORT}` (default: 15672)
- **Ollama API**: `http://localhost:11434`

## Network

This compose file creates and owns the `job-agent-network` bridge network.
All application services (telegram_bot, scrappers, etc.) connect to this network as external.

## Commands

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# View logs
docker compose logs -f

# View specific service logs
docker compose logs -f postgres

# Check service health
docker compose ps

# Restart a service
docker compose restart rabbitmq
```

## Troubleshooting

### Services not starting

Check logs for errors:
```bash
docker compose logs
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
