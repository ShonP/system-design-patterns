# An audit trail you can actually use in an incident: multi-region, tamper-evident,
# encrypted with a key you control, and streamed somewhere that can alert.
resource "aws_cloudwatch_log_group" "trail" {
  name              = "/aws/cloudtrail/good-trail"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.data.arn
}

data "aws_iam_policy_document" "cloudtrail_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudtrail" {
  name               = "cloudtrail-to-cloudwatch"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume.json
}

data "aws_iam_policy_document" "cloudtrail_logs" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.trail.arn}:*"]
  }
}

resource "aws_iam_role_policy" "cloudtrail" {
  name   = "cloudtrail-to-cloudwatch"
  role   = aws_iam_role.cloudtrail.id
  policy = data.aws_iam_policy_document.cloudtrail_logs.json
}

# CKV_AWS_252: a trail nobody is subscribed to is a trail nobody reads.
resource "aws_sns_topic" "trail" {
  name              = "cloudtrail-delivery"
  kms_master_key_id = aws_kms_key.data.arn
}

resource "aws_cloudtrail" "main" {
  name           = "good-trail"
  s3_bucket_name = aws_s3_bucket.logs.id
  s3_key_prefix  = "cloudtrail/"
  sns_topic_name = aws_sns_topic.trail.arn

  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.data.arn

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.trail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail.arn

  tags = { owner = "platform-team", env = "lab", data_classification = "internal" }
}
