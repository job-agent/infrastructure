variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "job-agent"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Database Configuration
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "jobs"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "jobagent"
}

# RabbitMQ Configuration
variable "mq_instance_type" {
  description = "Amazon MQ instance type"
  type        = string
  default     = "mq.t3.micro"
}

variable "mq_username" {
  description = "RabbitMQ admin username"
  type        = string
  default     = "jobagent"
}

# ECS Configuration
variable "telegram_bot_cpu" {
  description = "CPU units for telegram bot task (1024 = 1 vCPU)"
  type        = number
  default     = 512
}

variable "telegram_bot_memory" {
  description = "Memory for telegram bot task in MB"
  type        = number
  default     = 1024
}

variable "scrapper_cpu" {
  description = "CPU units for scrapper task"
  type        = number
  default     = 256
}

variable "scrapper_memory" {
  description = "Memory for scrapper task in MB"
  type        = number
  default     = 512
}

# Secrets (should be provided via tfvars or environment)
variable "telegram_bot_token" {
  description = "Telegram bot token"
  type        = string
  sensitive   = true
}

variable "openai_api_key" {
  description = "OpenAI API key (optional, for fallback)"
  type        = string
  sensitive   = true
  default     = ""
}

# GitHub Configuration
variable "github_repo" {
  description = "GitHub repository in format 'owner/repo' (e.g., 'job-agent/job-agent')"
  type        = string
}
