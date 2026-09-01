resource "aws_kms_key" "rds" {
  description             = "KMS key for security-labs RDS"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowAccountAdmin"
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
      Action    = "kms:*"
      Resource  = "*"
    }]
  })
}

# Query logging for Postgres (CKV2_AWS_30). Without a parameter group the engine
# logs nothing useful and you have no forensic trail after an incident.
resource "aws_db_parameter_group" "postgres" {
  name   = "good-db-pg16"
  family = "postgres16"

  parameter {
    name  = "log_statement"
    value = "all"
  }
  parameter {
    name  = "log_min_duration_statement"
    value = "1"
  }
  # CKV2_AWS_69: refuse non-TLS client connections at the engine, not just in the SG.
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
}

resource "random_password" "db" {
  length  = 32
  special = true
}

resource "aws_db_instance" "main" {
  identifier                          = "good-db"
  engine                              = "postgres"
  engine_version                      = "16.3"
  instance_class                      = "db.t3.micro"
  allocated_storage                   = 20
  username                            = "appuser"
  password                            = random_password.db.result
  publicly_accessible                 = false
  multi_az                            = true
  auto_minor_version_upgrade          = true
  copy_tags_to_snapshot               = true
  parameter_group_name                = aws_db_parameter_group.postgres.name
  storage_encrypted                   = true
  kms_key_id                          = aws_kms_key.rds.arn
  skip_final_snapshot                 = false
  final_snapshot_identifier           = "good-db-final"
  backup_retention_period             = 30
  deletion_protection                 = true
  iam_database_authentication_enabled = true

  enabled_cloudwatch_logs_exports = ["postgresql"]
  monitoring_interval             = 60
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn

  tags = { owner = "platform-team", env = "lab", data_classification = "internal" }
}
