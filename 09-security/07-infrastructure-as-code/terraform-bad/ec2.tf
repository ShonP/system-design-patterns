resource "aws_security_group" "ssh_open" {
  name        = "ssh-open"
  description = "SSH from anywhere"
  vpc_id      = "vpc-12345678"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.ssh_open.id]
  associate_public_ip_address = true
  metadata_options {
    http_tokens = "optional"
  }
  user_data = "API_KEY=hardcoded-secret-do-not-do-this"
  tags = { Name = "web" }
}
