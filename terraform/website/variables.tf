variable "aws_profile" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "domain" {
  type = string
}

variable "aws_kms_key" {
  type = object({
    name = string
  })
}

variable "aws_kms_alias" {
  type = object({
    name = string
  })
}

variable "AZURE_TENANT_ID" {
  type = string
}

variable "AZURE_SUBSCRIPTION_ID" {
  type = string
}

variable "ibm_region" {
  type = string
}

variable "IBM_DNS_DOMAIN_TARGET" {
  type = string
}


variable "ibm_satellite_location" {
  type = object({
    location     = string
    zones        = list(string)
    managed_from = string
  })
}

variable "ibm_iam_custom_role" {
  type = object({
    name         = string
    display_name = string
    description  = string
  })
}

variable "ibm_dns_zone" {
  type = object({
    description = string
  })
}
