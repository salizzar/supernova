provider "aws" {
  profile = local.aws_profile
  region  = local.aws_region

  default_tags {
    tags = {
      Project     = local.domain
      Environment = terraform.workspace
    }
  }
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = local.domain
}

module "acm" {
  depends_on = [
    aws_route53_zone.main
  ]

  providers = {
    aws.src = aws
    aws.dns = aws
  }

  source = "git::ssh://git@github.com/salizzar/terraform-modules.git//aws/acm-certificate?ref=v1.0.8"

  aws_acm_certificate = {
    domain_name               = local.domain
    subject_alternative_names = local.subject_alternative_names
    tags                      = {}
  }

  aws_route53_zone = {
    name = aws_route53_zone.main.name
  }
}

#tfsec:ignore:aws-cloudfront-enable-logging
resource "aws_cloudfront_distribution" "s3_distribution" {
  depends_on = [
    module.acm,
    aws_cloudfront_origin_access_identity.oai,
    module.s3-website,
    #   aws_wafv2_web_acl.waf
  ]

  origin {
    domain_name = module.s3-website.bucket_domain_name
    origin_id   = module.s3-website.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Marcelo Pinheiro"
  default_root_object = "index.html"
  # web_acl_id          = aws_wafv2_web_acl.waf.arn

  # TODO: enable this paraphernalia in the future
  #logging_config {
  #  include_cookies = true
  #  bucket          = module.s3-website-cf-logs.bucket_domain_name
  #  prefix          = "websites/marcelopinheiro.co/cloudfront-logs"
  #}

  aliases = concat([local.domain], local.subject_alternative_names)

  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = module.s3-website.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = local.one_day_in_seconds
    max_ttl                = local.one_day_in_seconds * local.days_per_month
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = module.s3-website.id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = local.one_day_in_seconds * local.days_per_month
    max_ttl                = local.one_year_in_seconds
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = module.s3-website.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = local.one_day_in_seconds * local.days_per_month
    max_ttl                = local.one_year_in_seconds
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  price_class = "PriceClass_200"

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = module.acm.certificate-id
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }
}

#resource "aws_wafv2_web_acl" "waf" {
#  name  = "${local.domain_with_underscore}_waf"
#  scope = "CLOUDFRONT"
#
#  default_action {
#    allow {}
#  }
#
#  visibility_config {
#    cloudwatch_metrics_enabled = true
#    metric_name                = "${local.domain_with_underscore}_waf"
#    sampled_requests_enabled   = true
#  }
#}

resource "aws_route53_record" "cloudfront" {
  zone_id = aws_route53_zone.main.id
  name    = local.domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "subject_alternative_names" {
  for_each = toset(local.subject_alternative_names)

  zone_id = aws_route53_zone.main.id
  name    = each.key
  type    = "CNAME"
  records = [aws_cloudfront_distribution.s3_distribution.domain_name]
  ttl     = 3600
}

data "external" "aws-sync" {
  depends_on = [
    module.s3-website
  ]

  program = [
    "/bin/bash", "bin/aws-website-sync"
  ]

  query = {
    folder                     = "../../website/html"
    bucket                     = module.s3-website.id
    profile                    = local.aws_profile
    cloudfront_distribution_id = aws_cloudfront_distribution.s3_distribution.id
  }
}

output "aws_sync_result" {
  value = data.external.aws-sync.result
}
