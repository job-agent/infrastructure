# Generate random password for RabbitMQ
resource "random_password" "mq_password" {
  length  = 32
  special = false
}

# Amazon MQ RabbitMQ Broker
resource "aws_mq_broker" "rabbitmq" {
  broker_name = "${var.project_name}-rabbitmq"

  engine_type                = "RabbitMQ"
  engine_version             = "3.13"
  host_instance_type         = var.mq_instance_type
  deployment_mode            = "SINGLE_INSTANCE"  # Single-AZ for cost savings
  publicly_accessible        = false
  auto_minor_version_upgrade = true

  subnet_ids         = [aws_subnet.private[0].id]
  security_groups    = [aws_security_group.mq.id]

  user {
    username = var.mq_username
    password = random_password.mq_password.result
  }

  logs {
    general = true
  }

  maintenance_window_start_time {
    day_of_week = "MONDAY"
    time_of_day = "04:00"
    time_zone   = "UTC"
  }

  tags = {
    Name = "${var.project_name}-rabbitmq"
  }
}
