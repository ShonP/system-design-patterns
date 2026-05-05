data "aws_iam_policy_document" "dev_read_only" {
  statement {
    sid    = "ReadOnlyAppData"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.data.arn,
      "${aws_s3_bucket.data.arn}/*"
    ]
  }
  statement {
    sid    = "DenyDelete"
    effect = "Deny"
    actions = [
      "s3:DeleteObject",
      "s3:DeleteBucket"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "dev_read_only" {
  name   = "dev-read-only"
  policy = data.aws_iam_policy_document.dev_read_only.json
}
