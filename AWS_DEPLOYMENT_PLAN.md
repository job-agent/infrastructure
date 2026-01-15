# AWS ECS Deployment Plan

## Overview

Deploy the job-agent platform to AWS ECS with:
- **Bedrock** for LLM tasks (Claude 3 Sonnet) and embeddings (Titan)
- **Amazon RDS** for PostgreSQL with pgvector (Single-AZ)
- **Amazon MQ** for RabbitMQ (Single-AZ)
- **ECS Fargate** for application containers
- **Terraform** for infrastructure-as-code
- **Auto-switching** between Ollama (local) and Bedrock (AWS)

**Target Region:** us-east-1

---

## Phase 1: Code Changes (Bedrock Integration)

### 1.1 Add Bedrock Provider

**File:** `job-agent-platform/packages/job-agent-backend/src/job_agent_backend/model_providers/providers/bedrock.py`

```python
class BedrockProvider(BaseModelProvider):
    """AWS Bedrock LLM provider using Claude 3 Sonnet."""

    def __init__(
        self,
        model_name: str = "anthropic.claude-3-sonnet-20240229-v1:0",
        temperature: float = 0.0,
        region: str | None = None,
        **kwargs
    ):
        # Uses boto3 credentials chain (env vars, IAM role, etc.)

    def get_model(self) -> BaseChatModel:
        from langchain_aws import ChatBedrock
        return ChatBedrock(...)
```

### 1.2 Add Bedrock Embeddings Provider

**File:** `job-agent-platform/packages/job-agent-backend/src/job_agent_backend/model_providers/providers/bedrock_embeddings.py`

```python
class BedrockEmbeddingsProvider(BaseModelProvider):
    """AWS Bedrock Titan Embeddings provider."""

    def __init__(
        self,
        model_name: str = "amazon.titan-embed-text-v2:0",
        region: str | None = None,
        **kwargs
    ):
        pass

    def get_model(self) -> Embeddings:
        from langchain_aws import BedrockEmbeddings
        return BedrockEmbeddings(...)
```

### 1.3 Update Provider Maps

**File:** `model_providers/mappers/provider_map.py`
- Add `"bedrock": BedrockProvider`
- Add `"bedrock-embeddings": BedrockEmbeddingsProvider`

**File:** `model_providers/mappers/model_provider_map.py`
- Add `"anthropic.claude-3-sonnet-20240229-v1:0": "bedrock"`
- Add `"amazon.titan-embed-text-v2:0": "bedrock-embeddings"`

### 1.4 Update Container Configuration

**File:** `model_providers/container.py`

Create environment-aware configuration:
```python
import os

def _get_default_llm_provider():
    if os.getenv("AWS_EXECUTION_ENV") or os.getenv("USE_BEDROCK"):
        return BedrockProvider(model_name="anthropic.claude-3-sonnet-20240229-v1:0")
    return OllamaProvider(model_name="phi3:mini")

def _get_default_embedding_provider():
    if os.getenv("AWS_EXECUTION_ENV") or os.getenv("USE_BEDROCK"):
        return BedrockEmbeddingsProvider(model_name="amazon.titan-embed-text-v2:0")
    return TransformersProvider(model_name="sentence-transformers/...", task="embedding")
```

### 1.5 Add Dependencies

**File:** `job-agent-platform/packages/job-agent-backend/pyproject.toml`
```toml
dependencies = [
    ...
    "langchain-aws>=0.2.0",
    "boto3>=1.34.0",
]
```

### 1.6 Files to Modify

| File | Change |
|------|--------|
| `model_providers/providers/bedrock.py` | Create new |
| `model_providers/providers/bedrock_embeddings.py` | Create new |
| `model_providers/providers/__init__.py` | Export new providers |
| `model_providers/mappers/provider_map.py` | Add bedrock mappings |
| `model_providers/mappers/model_provider_map.py` | Add model mappings |
| `model_providers/container.py` | Environment-aware defaults |
| `model_providers/__init__.py` | Export new providers |
| `job-agent-backend/pyproject.toml` | Add langchain-aws |

---

## Phase 2: Terraform Infrastructure

### 2.1 Directory Structure

```
infrastructure/
└── terraform/
    ├── main.tf              # Provider config, backend
    ├── variables.tf         # Input variables
    ├── outputs.tf           # Output values
    ├── vpc.tf               # VPC, subnets, NAT
    ├── security_groups.tf   # Security group rules
    ├── rds.tf               # PostgreSQL with pgvector
    ├── mq.tf                # Amazon MQ (RabbitMQ)
    ├── ecr.tf               # Container registries
    ├── ecs.tf               # ECS cluster, services
    ├── iam.tf               # IAM roles and policies
    ├── secrets.tf           # Secrets Manager
    ├── cloudwatch.tf        # Log groups, alarms
    └── terraform.tfvars.example
```

### 2.2 VPC Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    VPC (10.0.0.0/16)                        │
│                                                             │
│  ┌──────────────────────┐  ┌──────────────────────┐        │
│  │  Public Subnet A     │  │  Public Subnet B     │        │
│  │  10.0.1.0/24        │  │  10.0.2.0/24        │        │
│  │  (NAT Gateway)       │  │                      │        │
│  └──────────────────────┘  └──────────────────────┘        │
│                                                             │
│  ┌──────────────────────┐  ┌──────────────────────┐        │
│  │  Private Subnet A    │  │  Private Subnet B    │        │
│  │  10.0.10.0/24       │  │  10.0.11.0/24       │        │
│  │  (ECS Tasks, RDS)    │  │  (ECS Tasks, RDS)   │        │
│  └──────────────────────┘  └──────────────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

### 2.3 AWS Resources

| Resource | Type | Purpose |
|----------|------|---------|
| RDS PostgreSQL | db.t3.micro (Single-AZ) | Database with pgvector |
| Amazon MQ | mq.t3.micro (Single-AZ) | RabbitMQ broker |
| ECS Cluster | Fargate | Container orchestration |
| ECR | 2 repos | telegram-bot, scrapper-mock |
| Secrets Manager | 1 secret | All app secrets |
| CloudWatch Logs | 2 groups | Container logs |
| NAT Gateway | 1 | Outbound internet for private subnets |

### 2.4 ECS Task Definitions

**telegram-bot:**
- CPU: 512, Memory: 1024
- Environment: DATABASE_URL, RABBITMQ_URL, BOT_TOKEN, USE_BEDROCK=true
- IAM Role: bedrock:InvokeModel permission

**scrapper-service:**
- CPU: 256, Memory: 512
- Environment: RABBITMQ_URL

### 2.5 IAM Policies

**ECS Task Role (for Bedrock access):**
```json
{
  "Effect": "Allow",
  "Action": [
    "bedrock:InvokeModel",
    "bedrock:InvokeModelWithResponseStream"
  ],
  "Resource": [
    "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-sonnet-*",
    "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-*"
  ]
}
```

---

## Phase 3: CI/CD Pipeline

### 3.1 GitHub Actions Workflow

**File:** `.github/workflows/deploy.yml`

```yaml
name: Deploy to AWS ECS

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - Checkout
      - Configure AWS credentials
      - Login to ECR
      - Build and push telegram-bot image
      - Build and push scrapper image
      - Deploy to ECS (update service)
```

### 3.2 ECR Build Commands

```bash
# telegram-bot
docker build -t telegram-bot \
  --ssh default \
  -f packages/telegram_bot/Dockerfile .

# scrapper-service
docker build -t scrapper-service \
  -f packages/scrapper-service/Dockerfile .
```

---

## Phase 4: Observability (Basic)

### 4.1 CloudWatch Logs Only

- Container logs automatically sent to CloudWatch Logs
- One log group per ECS service
- 30-day retention

### 4.2 Future Enhancement (Not in MVP)

Can add later:
- CloudWatch Container Insights
- AWS X-Ray for distributed tracing
- Custom CloudWatch alarms

---

## Implementation Order

1. **Code changes** (Phase 1) - Add Bedrock providers
2. **Run tests** locally with Bedrock (need AWS credentials)
3. **Create Terraform** infrastructure (Phase 2)
4. **Deploy infrastructure** with `terraform apply`
5. **Setup CI/CD** (Phase 3)
6. **Deploy application** containers
7. **Configure observability** (Phase 4)

---

## Verification Steps

1. **Unit tests:** Run existing tests with mocked Bedrock
2. **Integration test:** Test Bedrock locally with AWS credentials
3. **Infrastructure:** `terraform plan` shows expected resources
4. **Deployment:** ECS tasks running healthy
5. **E2E:** Telegram bot responds to commands

---

## Cost Estimate (Monthly, Single-AZ)

| Service | Estimate |
|---------|----------|
| RDS db.t3.micro (Single-AZ) | ~$15 |
| Amazon MQ mq.t3.micro | ~$25 |
| ECS Fargate (2 tasks, 0.5 vCPU each) | ~$15 |
| NAT Gateway + data transfer | ~$35 |
| ECR storage | ~$1 |
| CloudWatch Logs | ~$5 |
| Bedrock Claude 3 Sonnet | ~$50-200 (usage-based) |
| Bedrock Titan Embeddings | ~$10-50 (usage-based) |
| **Total** | ~$150-350/month |

**Note:** Bedrock costs depend on usage. Claude 3 Sonnet: $3/1M input, $15/1M output tokens.

---

## Files to Create/Modify

### New Files
- `model_providers/providers/bedrock.py`
- `model_providers/providers/bedrock_embeddings.py`
- `infrastructure/terraform/*.tf` (all terraform files)
- `.github/workflows/deploy.yml`

### Modified Files
- `model_providers/providers/__init__.py`
- `model_providers/mappers/provider_map.py`
- `model_providers/mappers/model_provider_map.py`
- `model_providers/container.py`
- `model_providers/__init__.py`
- `job-agent-backend/pyproject.toml`
