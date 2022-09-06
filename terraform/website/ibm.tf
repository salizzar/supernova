provider "ibm" {
  region = var.ibm_region
}

provider "ibm" {
  region                = var.ibm_region
  iaas_classic_username = var.IAAS_CLASSIC_USERNAME
  iaas_classic_api_key  = var.IAAS_CLASSIC_API_KEY
  alias                 = "legacy"
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

resource "ibm_dns_zone" "website" {
  provider = ibm.legacy

  name        = local.domain
  label       = local.domain_without_dot
  instance_id = ibm_resource_instance.ri.guid
  description = var.ibm_dns_zone.description
}

resource "ibm_dns_resource_record" "cdn" {
  provider = ibm.legacy

  zone_id     = ibm_dns_zone.website.zone_id
  instance_id = ibm_resource_instance.ri.guid
  type        = "AAAA"
  name        = "@"
  rdata       = ibm_cdn.cdn.id
}
