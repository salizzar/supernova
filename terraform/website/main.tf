locals {
  aws_profile        = var.aws_profile
  aws_region         = var.aws_region
  domain             = var.domain
  aws_kms_key_name   = var.aws_kms_key.name
  sanitized_domain   = replace(local.domain, ".", "_")
  domain_without_dot = replace(local.domain, ".", "")

  one_hour_in_seconds = 3600
  one_day_in_seconds  = 86400
  days_per_year       = 365
  days_per_month      = 30
  one_year_in_seconds = local.one_day_in_seconds * local.days_per_year

  subject_alternative_names = [
    "www.${local.domain}"
  ]
}
