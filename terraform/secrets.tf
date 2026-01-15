# Secrets Manager for application secrets
resource "aws_secretsmanager_secret" "app_secrets" {
  name                    = "${var.project_name}/app-secrets"
  recovery_window_in_days = 0  # Immediate deletion for dev

  tags = {
    Name = "${var.project_name}-app-secrets"
  }
}

resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id

  secret_string = jsonencode({
    DATABASE_URL       = "postgresql://${var.db_username}:${random_password.db_password.result}@${aws_db_instance.main.endpoint}/${var.db_name}"
    RABBITMQ_URL       = "amqps://${var.mq_username}:${random_password.mq_password.result}@${aws_mq_broker.rabbitmq.instances[0].endpoints[0]}"
    JOB_AGENT_BOT_TOKEN = var.telegram_bot_token
    OPENAI_API_KEY     = var.openai_api_key
    POSTGRES_USER      = var.db_username
    POSTGRES_PASSWORD  = random_password.db_password.result
    POSTGRES_DB        = var.db_name
    RABBITMQ_USER      = var.mq_username
    RABBITMQ_PASSWORD  = random_password.mq_password.result
  })
}
