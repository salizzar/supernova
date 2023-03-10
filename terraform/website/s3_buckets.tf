#tfsec:ignore:aws-s3-enable-bucket-logging
#tfsec:ignore:aws-s3-enable-bucket-encryption
#tfsec:ignore:aws-s3-encryption-customer-key
module "s3-website" {
  source = "git::ssh://git@github.com/salizzar/terraform-modules.git//aws/s3-bucket?ref=v1.0.9"

  aws_iam_policy_document = {
    statement_allow_access_key_administrators = ["*"]
  }

  aws_kms_key = {
    enabled = true

    description             = "Marcelo Pinheiro Website KMS Key"
    deletion_window_in_days = 7
    enable_key_rotation     = true
    tags                    = null
  }

  aws_kms_alias = {
    enabled = true

    name = var.aws_kms_alias.name
  }

  aws_s3_bucket = {
    bucket = local.domain
    tags   = null
  }

  aws_s3_bucket_acl = {
    acl = "private"
  }

  aws_s3_bucket_versioning = {
    versioning_configuration = {
      status = "Enabled"
    }
  }

  aws_s3_bucket_website_configuration = {
    index_document = {
      suffix = "index.html"
    }

    error_document = {
      suffix = "404.html"
    }

    redirect_all_requests_to = null
    routing_rules            = null
  }


  aws_s3_bucket_server_side_encryption_configuration = {
    enabled = false

    # S3 static website buckets cannot be encrypted for some weid reason I don't understand why
    rules = null
    #   rules = [
    #     {
    #       sse_algorithm = "aws:kms"
    #     }
    #   ]
  }

  aws_s3_bucket_policy = {
    enabled = true
    policy  = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AddCloudFrontOriginAccessOnly",
            "Effect": "Allow",
            "Principal": {
              "AWS": "${aws_cloudfront_origin_access_identity.oai.iam_arn}"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${local.domain}/*"
        }
    ]
}
POLICY
  }

  aws_s3_bucket_public_access_block = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }

  aws_s3_log_bucket = {
    enabled = false
    bucket  = null
    tags    = null
  }

  aws_s3_log_bucket_acl        = null
  aws_s3_log_bucket_versioning = null
  aws_s3_bucket_logging        = null

  aws_dynamodb_table = {
    enabled        = false
    name           = null
    read_capacity  = null
    tags           = null
    write_capacity = null
  }
}

output "s3_website_bucket_domain_name" {
  value = module.s3-website.bucket_domain_name
}

output "s3_website_bucket_website_endpoint" {
  value = module.s3-website.bucket_website_endpoint
}

output "s3_website_bucket_website_domain" {
  value = module.s3-website.bucket_website_domain
}

resource "aws_route53_zone" "main" {
  name = local.domain
}

# TODO: work in this paraphernalia in the future
#module "s3-website-cf-logs" {
#  # source = "git::ssh://git@github.com/salizzar/terraform-modules.git//aws/s3-bucket?ref=v1.0.8"
#
#  aws_iam_policy_document = {
#    statement_allow_access_key_administrators = ["*"]
#  }
#
#  aws_kms_key = {
#    enabled = true
#
#    description             = "Marcelo Pinheiro KMS Key for CloudFront Logs"
#    deletion_window_in_days = 7
#    enable_key_rotation     = true
#    tags                    = null
#  }
#
#  aws_kms_alias = {
#    enabled = true
#
#    name = "${var.aws_kms_alias.name}_cf_logs"
#  }
#
#  aws_s3_bucket = {
#    bucket = "${replace(local.sanitized_domain, "_", "-")}-cf-logs"
#    acl    = "private"
#
#    versioning = {
#      enabled = true
#    }
#
#    website = null
#    tags    = null
#  }
#
#  aws_s3_bucket_server_side_encryption_configuration = {
#    enabled = true
#
#    rules = [
#      {
#        sse_algorithm = "aws:kms"
#      }
#    ]
#  }
#
#  aws_s3_bucket_policy = {
#    enabled = true
#    policy  = <<POLICY
#{
#    "Version": "2012-10-17",
#    "Statement": [
#        {
#            "Sid": "AllowCloudFrontToDeliverLogFiles",
#            "Effect": "Allow",
#            "Principal": {
#              "Service": "delivery.logs.amazonaws.com"
#            },
#            "Action": [
#              "s3:GetBucketAcl",
#              "s3:PutBucketAcl"
#            ],
#            "Resource": "arn:aws:s3:::${replace(local.sanitized_domain, "_", "-")}-cf-logs"
#        }
#    ]
#}
#POLICY
#  }
#
#  aws_s3_bucket_public_access_block = {
#    block_public_acls       = true
#    block_public_policy     = true
#    ignore_public_acls      = true
#    restrict_public_buckets = true
#  }
#
#  aws_s3_log_bucket = {
#    enabled = true
#
#    bucket = "${replace(local.sanitized_domain, "_", "-")}-s3-logs"
#    acl    = "private"
#
#    versioning = {
#      enabled = false
#    }
#  }
#
#  aws_s3_bucket_logging = {
#    target_prefix = null
#  }
#
#  aws_dynamodb_table = {
#    enabled        = false
#    name           = null
#    read_capacity  = null
#    tags           = null
#    write_capacity = null
#  }
#}

