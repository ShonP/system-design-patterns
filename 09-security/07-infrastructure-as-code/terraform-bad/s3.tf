resource "aws_s3_bucket" "data" {
  bucket = "security-labs-bad-bucket"
  acl    = "public-read"
  tags = {
    Name = "data"
  }
}
