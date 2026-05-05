resource "aws_kms_key" "rds" {
  description             = "KMS key for security-labs RDS"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "random_password" "db" {
  length  = 32
  special = true
}

resource "aws_db_instance" "main" {
  identifier              = "good-db"
  engine                  = "postgres"
  engine_version          = "16.3"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  username                = "appuser"
  password                = random_password.db.result
  publicly_accessible     = false
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.rds.arn
  skip_final_snapshot     = false
  final_snapshot_identifier = "good-db-final"
  backup_retention_period = 30
  deletion_protection     = true
  iam_database_authentication_enabled = true

  enabled_cloudwatch_logs_exports = ["postgresql"]
  monitoring_interval             = 60
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn

  tags = { owner = "platform-team", env = "lab", data_classification = "internal" }
}

terraform {
  required_providers {
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}
