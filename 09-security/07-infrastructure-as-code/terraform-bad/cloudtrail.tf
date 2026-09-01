# The audit trail nobody checks until the week they need it.
resource "aws_s3_bucket" "trail" {
  bucket = "security-labs-bad-trail"
}

resource "aws_cloudtrail" "main" {
  name           = "bad-trail"
  s3_bucket_name = aws_s3_bucket.trail.id

  is_multi_region_trail         = false # only us-east-1 is recorded
  enable_log_file_validation    = false # nobody can prove the log wasn't edited
  include_global_service_events = false # IAM/STS calls are invisible
  # no kms_key_id       -> trail objects use default S3 encryption
  # no cloud_watch_logs -> no alerting on the trail, ever
}
