resource "aws_db_instance" "main" {
  identifier        = "bad-db"
  engine            = "postgres"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  username          = "admin"
  password          = "hunter2hunter2"
  publicly_accessible       = true
  storage_encrypted         = false
  skip_final_snapshot       = true
  backup_retention_period   = 0
  deletion_protection       = false
  iam_database_authentication_enabled = false
}

resource "aws_iam_policy" "admin_everything" {
  name   = "dev-admin-everything"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "*"
      Resource = "*"
    }]
  })
}
