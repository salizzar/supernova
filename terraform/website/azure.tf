provider "azurerm" {
  subscription_id = var.AZURE_SUBSCRIPTION_ID
  client_id       = var.AZURE_CLIENT_ID
  client_secret   = var.AZURE_CLIENT_SECRET
  tenant_id       = var.AZURE_TENANT_ID

  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = local.domain
  location = "East US 2"
}
#
#resource "azurerm_subscription" "subscription" {
#  subscription_name = "Pay-As-You-Go"
#  subscription_id   = var.AZURE_SUBSCRIPTION_ID
#}

data "azuread_client_config" "current" {}

resource "azuread_application" "app" {
  display_name = local.domain
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "marcelopinheiro" {
  application_id               = azuread_application.app.application_id
  app_role_assignment_required = true
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azurerm_storage_account" "website" {
  name                      = local.domain_without_dot
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  min_tls_version           = "TLS1_2"
  enable_https_traffic_only = true

  blob_properties {
    versioning_enabled = true
  }

  custom_domain {
    name = local.domain
  }

  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }
}

resource "azurerm_cdn_profile" "cdn" {
  name                = local.domain_without_dot
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard_Microsoft"
}

resource "azurerm_cdn_endpoint" "website" {
  name                          = "marcelopinheiroco"
  location                      = "Global"
  profile_name                  = azurerm_cdn_profile.cdn.name
  resource_group_name           = azurerm_resource_group.rg.name
  is_http_allowed               = true
  is_https_allowed              = true
  is_compression_enabled        = true
  querystring_caching_behaviour = "NotSet"
  content_types_to_compress = [
    "text/html",
    "text/css",
    "image/jpeg"
  ]

  origin {
    name       = local.domain_without_dot
    host_name  = local.sanitized_primary_web_endpoint
    http_port  = 80
    https_port = 443
  }

  origin_host_header = local.sanitized_primary_web_endpoint

  delivery_rule {
    name  = "RewriteToIndex"
    order = "1"

    url_file_extension_condition {
      operator     = "LessThan"
      match_values = ["1"]
    }

    url_rewrite_action {
      destination             = "/index.html"
      source_pattern          = "/"
      preserve_unmatched_path = "false"
    }
  }

  delivery_rule {
    name  = "EnforceHTTPS"
    order = "2"

    request_scheme_condition {
      operator     = "Equal"
      match_values = ["HTTP"]
    }

    url_redirect_action {
      redirect_type = "Found"
      protocol      = "Https"
    }
  }
}

resource "azurerm_cdn_endpoint_custom_domain" "website" {
  depends_on = [
    azurerm_dns_cname_record.www
  ]

  name            = local.domain_without_dot
  cdn_endpoint_id = azurerm_cdn_endpoint.website.id
  host_name       = "${azurerm_dns_cname_record.www.name}.${azurerm_dns_zone.website.name}"

  cdn_managed_https {
    certificate_type = "Dedicated"
    protocol_type    = "ServerNameIndication"
    tls_version      = "TLS12"
  }
}

resource "azurerm_dns_zone" "website" {
  name                = local.domain
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_dns_a_record" "cdn" {
  depends_on = [
    azurerm_cdn_endpoint.website
  ]

  name                = "@"
  zone_name           = azurerm_dns_zone.website.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = local.one_day_in_seconds

  target_resource_id = azurerm_cdn_endpoint.website.id
}

resource "azurerm_dns_cname_record" "www" {
  depends_on = [
    azurerm_cdn_endpoint.website
  ]

  name                = "www"
  zone_name           = azurerm_dns_zone.website.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = local.one_day_in_seconds

  target_resource_id = azurerm_cdn_endpoint.website.id
}

# enable CDN url to obtain a custom domain
resource "azurerm_dns_cname_record" "cdnverify" {
  name                = "cdnverify"
  zone_name           = azurerm_dns_zone.website.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = local.one_day_in_seconds
  target_resource_id  = azurerm_cdn_endpoint.website.id
}

# enable Azure Blob url to obtain a custom domain
resource "azurerm_dns_cname_record" "asverify" {
  name                = "asverify"
  zone_name           = azurerm_dns_zone.website.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = local.one_day_in_seconds
  record              = "asverify.${local.sanitized_primary_web_endpoint}"
}

data "azurerm_subscription" "primary" {
}

data "azurerm_client_config" "current" {
}

data "external" "azure-sync" {
  depends_on = [
    azurerm_storage_account.website
  ]

  program = [
    "/bin/bash", "bin/azure-website-sync"
  ]

  query = {
    folder                = "../../website/html"
    resource_group        = azurerm_resource_group.rg.name
    cdn_endpoint          = azurerm_cdn_endpoint.website.id
    storage_container_url = "https://${azurerm_storage_account.website.primary_blob_host}/$web" # hack to azcopy proper handle folder name with azcopy in background
  }
}

output "azuread_application_id" {
  value = azuread_application.app.id
}

output "azuread_service_principal_application_tenant_id" {
  value = azuread_service_principal.marcelopinheiro.application_tenant_id
}

output "azure_sync_result" {
  value = data.external.azure-sync.result
}
