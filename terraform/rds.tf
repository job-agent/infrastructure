# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# Generate random password for RDS
resource "random_password" "db_password" {
  length  = 32
  special = false
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-postgres"

  # Engine settings
  engine               = "postgres"
  engine_version       = "16.3"
  instance_class       = var.db_instance_class
  allocated_storage    = 20
  max_allocated_storage = 100
  storage_type         = "gp3"
  storage_encrypted    = true

  # Database settings
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  # Network settings
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = false  # Single-AZ for cost savings

  # Backup settings
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # Performance Insights
  performance_insights_enabled = false

  # Other settings
  skip_final_snapshot       = true
  final_snapshot_identifier = "${var.project_name}-final-snapshot"
  deletion_protection       = false
  copy_tags_to_snapshot     = true

  # Enable pgvector extension via parameter group
  parameter_group_name = aws_db_parameter_group.postgres.name

  tags = {
    Name = "${var.project_name}-postgres"
  }
}

# Parameter group to enable pgvector
resource "aws_db_parameter_group" "postgres" {
  name   = "${var.project_name}-postgres-params"
  family = "postgres16"

  # pgvector is available in RDS PostgreSQL 16 by default
  # Just need to CREATE EXTENSION pgvector; in the database

  tags = {
    Name = "${var.project_name}-postgres-params"
  }
}
