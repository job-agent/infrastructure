output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "ecr_telegram_bot_url" {
  description = "ECR repository URL for telegram bot"
  value       = aws_ecr_repository.telegram_bot.repository_url
}

output "ecr_scrapper_url" {
  description = "ECR repository URL for scrapper"
  value       = aws_ecr_repository.scrapper.repository_url
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "rabbitmq_endpoint" {
  description = "Amazon MQ RabbitMQ endpoint"
  value       = aws_mq_broker.rabbitmq.instances[0].endpoints[0]
  sensitive   = true
}

output "secrets_arn" {
  description = "Secrets Manager ARN"
  value       = aws_secretsmanager_secret.app_secrets.arn
}

output "telegram_bot_service_name" {
  description = "Telegram bot ECS service name"
  value       = aws_ecs_service.telegram_bot.name
}

output "scrapper_service_name" {
  description = "Scrapper ECS service name"
  value       = aws_ecs_service.scrapper.name
}

output "telegram_bot_log_group" {
  description = "CloudWatch log group for telegram bot"
  value       = aws_cloudwatch_log_group.telegram_bot.name
}

output "scrapper_log_group" {
  description = "CloudWatch log group for scrapper"
  value       = aws_cloudwatch_log_group.scrapper.name
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions - add as AWS_ROLE_ARN secret"
  value       = aws_iam_role.github_actions.arn
}
