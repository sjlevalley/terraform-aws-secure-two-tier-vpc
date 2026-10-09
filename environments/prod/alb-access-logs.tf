data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

resource "aws_s3_bucket" "alb_access_logs" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = "${local.name_prefix}-alb-access-logs-${data.aws_caller_identity.current.account_id}"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-access-logs"
  })
}

resource "aws_s3_bucket_public_access_block" "alb_access_logs" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = aws_s3_bucket.alb_access_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_access_logs" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = aws_s3_bucket.alb_access_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_access_logs" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = aws_s3_bucket.alb_access_logs[0].id

  rule {
    id     = "expire-alb-access-logs"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = var.alb_access_logs_retention_days
    }
  }
}

data "aws_iam_policy_document" "alb_access_logs" {
  count = var.enable_alb_access_logs ? 1 : 0

  statement {
    sid = "AllowElasticLoadBalancingLogDelivery"

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = [
      "${aws_s3_bucket.alb_access_logs[0].arn}/public-alb/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
      "${aws_s3_bucket.alb_access_logs[0].arn}/internal-alb/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:${data.aws_partition.current.partition}:elasticloadbalancing:${var.aws_region}:${data.aws_caller_identity.current.account_id}:loadbalancer/*"
      ]
    }
  }

  statement {
    sid = "DenyInsecureTransport"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.alb_access_logs[0].arn,
      "${aws_s3_bucket.alb_access_logs[0].arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "alb_access_logs" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = aws_s3_bucket.alb_access_logs[0].id
  policy = data.aws_iam_policy_document.alb_access_logs[0].json
}
