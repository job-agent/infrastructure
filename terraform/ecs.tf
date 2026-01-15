# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"  # Can enable for additional monitoring
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# ECS Task Definition for Telegram Bot
resource "aws_ecs_task_definition" "telegram_bot" {
  family                   = "${var.project_name}-telegram-bot"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.telegram_bot_cpu
  memory                   = var.telegram_bot_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "telegram-bot"
      image = "${aws_ecr_repository.telegram_bot.repository_url}:latest"

      essential = true

      environment = [
        { name = "USE_BEDROCK", value = "true" },
        { name = "AWS_REGION", value = var.aws_region },
        { name = "OTEL_ENABLED", value = "false" },
      ]

      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:DATABASE_URL::"
        },
        {
          name      = "RABBITMQ_URL"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:RABBITMQ_URL::"
        },
        {
          name      = "JOB_AGENT_BOT_TOKEN"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:JOB_AGENT_BOT_TOKEN::"
        },
        {
          name      = "OPENAI_API_KEY"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:OPENAI_API_KEY::"
        },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.telegram_bot.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "python -c 'import sys; sys.exit(0)'"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-telegram-bot-task"
  }
}

# ECS Task Definition for Scrapper
resource "aws_ecs_task_definition" "scrapper" {
  family                   = "${var.project_name}-scrapper"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.scrapper_cpu
  memory                   = var.scrapper_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "scrapper"
      image = "${aws_ecr_repository.scrapper.repository_url}:latest"

      essential = true

      environment = [
        { name = "OTEL_ENABLED", value = "false" },
      ]

      secrets = [
        {
          name      = "RABBITMQ_URL"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:RABBITMQ_URL::"
        },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.scrapper.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-scrapper-task"
  }
}

# ECS Service for Telegram Bot
resource "aws_ecs_service" "telegram_bot" {
  name            = "${var.project_name}-telegram-bot"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.telegram_bot.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  # Don't recreate service if task definition changes (managed by CI/CD)
  lifecycle {
    ignore_changes = [task_definition]
  }

  tags = {
    Name = "${var.project_name}-telegram-bot-service"
  }

  depends_on = [
    aws_db_instance.main,
    aws_mq_broker.rabbitmq
  ]
}

# ECS Service for Scrapper
resource "aws_ecs_service" "scrapper" {
  name            = "${var.project_name}-scrapper"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.scrapper.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  # Don't recreate service if task definition changes (managed by CI/CD)
  lifecycle {
    ignore_changes = [task_definition]
  }

  tags = {
    Name = "${var.project_name}-scrapper-service"
  }

  depends_on = [
    aws_mq_broker.rabbitmq
  ]
}
