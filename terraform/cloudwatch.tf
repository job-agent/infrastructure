# CloudWatch Log Group for Telegram Bot
resource "aws_cloudwatch_log_group" "telegram_bot" {
  name              = "/ecs/${var.project_name}/telegram-bot"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-telegram-bot-logs"
  }
}

# CloudWatch Log Group for Scrapper
resource "aws_cloudwatch_log_group" "scrapper" {
  name              = "/ecs/${var.project_name}/scrapper"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-scrapper-logs"
  }
}
