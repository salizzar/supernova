provider "ibm" {
  region = var.ibm_region
}

resource "ibm_resource_group" "rg" {
  name = local.domain_without_dot
}

resource "ibm_resource_instance" "ri" {
  name              = local.domain
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = "global"
  resource_group_id = ibm_resource_group.rg.id
}

resource "ibm_cos_bucket" "cos_bucket" {
  bucket_name          = local.domain_with_dash
  resource_instance_id = ibm_resource_instance.ri.id
  storage_class        = "standard"
  endpoint_type        = "public"
  region_location      = var.ibm_region

  object_versioning {
    enable = true
  }
}

resource "ibm_cdn" "cdn" {
  host_name        = local.domain
  cname            = local.domain_without_dot
  bucket_name      = ibm_cos_bucket.cos_bucket.bucket_name
  certificate_type = "SHARED_SAN_CERT"
  http_port        = 80
  https_port       = 443
  origin_address   = ibm_cos_bucket.cos_bucket.s3_endpoint_public
  origin_type      = "OBJECT_STORAGE"
  protocol         = "HTTPS"
  vendor_name      = "akamai"
}

#
# that danm weird code, dude
#

resource "ibm_dns_domain" "website" {
  name   = local.domain
  target = var.IBM_DNS_DOMAIN_TARGET
}

output "ibm_dns_domain_id" {
  value = ibm_dns_domain.website.id
}

output "ibm_dns_domain_serial" {
  value = ibm_dns_domain.website.serial
}

output "ibm_dns_domain_update_date" {
  value = ibm_dns_domain.website.update_date
}

resource "ibm_resource_instance" "pdns" {
  name              = local.domain
  resource_group_id = ibm_resource_group.rg.id
  location          = "global"
  service           = "dns-svcs"
  plan              = "standard-dns"
}

resource "ibm_dns_zone" "website" {
  name        = local.domain
  instance_id = ibm_resource_instance.pdns.guid
  description = var.ibm_dns_zone.description
}

resource "ibm_dns_resource_record" "www" {
  zone_id     = ibm_dns_zone.website.zone_id
  instance_id = ibm_resource_instance.pdns.guid
  type        = "CNAME"
  name        = "www"
  rdata       = "${local.domain_without_dot}.cdn.appdomain.cloud"
}

resource "ibm_dns_resource_record" "acme" {
  zone_id     = ibm_dns_zone.website.zone_id
  instance_id = ibm_resource_instance.pdns.guid
  type        = "CNAME"
  name        = "_acme-challenge.${local.domain}"
  rdata       = "${local.domain}.ak-acme-challenge.cdn.appdomain.cloud"
}

