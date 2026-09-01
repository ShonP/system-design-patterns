resource "aws_security_group" "web" {
  name        = "web"
  description = "Web traffic only"
  vpc_id      = "vpc-12345678"

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    description = "Outbound HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# CKV2_AWS_41: an instance profile means the app gets short-lived, scoped
# credentials from IMDSv2 instead of a long-lived access key baked into user_data.
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "web" {
  name               = "web-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy" "web" {
  name   = "web-instance-policy"
  role   = aws_iam_role.web.id
  policy = data.aws_iam_policy_document.dev_read_only.json
}

resource "aws_iam_instance_profile" "web" {
  name = "web-instance-profile"
  role = aws_iam_role.web.name
}

resource "aws_instance" "web" {
  ami                         = "ami-12345678"
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.web.id]
  iam_instance_profile        = aws_iam_instance_profile.web.name
  associate_public_ip_address = false
  monitoring                  = true
  ebs_optimized               = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"   # IMDSv2 only
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted = true
  }

  tags = {
    Name                = "web"
    owner               = "platform-team"
    env                 = "lab"
    data_classification = "internal"
  }
}
