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
