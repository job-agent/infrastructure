# ECR Repository for Telegram Bot
resource "aws_ecr_repository" "telegram_bot" {
  name                 = "${var.project_name}/telegram-bot"
  image_tag_mutability = "MUTABLE"
  force_delete         = true  # Allow deletion even with images

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-telegram-bot"
  }
}

# ECR Repository for Scrapper Service
resource "aws_ecr_repository" "scrapper" {
  name                 = "${var.project_name}/scrapper"
  image_tag_mutability = "MUTABLE"
  force_delete         = true  # Allow deletion even with images

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-scrapper"
  }
}

# Lifecycle policy to keep only recent images
resource "aws_ecr_lifecycle_policy" "telegram_bot" {
  repository = aws_ecr_repository.telegram_bot.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "scrapper" {
  repository = aws_ecr_repository.scrapper.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
