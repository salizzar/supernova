provider "azurerm" {
  features {}
}

variable "AZURE_TENANT_ID" {
  type = string
}

variable "AZURE_SUBSCRIPTION_ID" {
  type = string
}

resource "azurerm_resource_group" "rg" {
  name     = local.domain
  location = "East US 2"
}

resource "azurerm_subscription" "subscription" {
  subscription_name = "Azure subscription"
  subscription_id   = var.AZURE_SUBSCRIPTION_ID
}

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
  min_tls_version           = "TLS1_0"
  enable_https_traffic_only = true

  blob_properties {
    versioning_enabled = true
  }

  # custom_domain {
  #   name = local.domain
  # }

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
    host_name  = replace(replace(azurerm_storage_account.website.primary_web_endpoint, "https://", ""), "/", "")
    http_port  = 80
    https_port = 443
  }

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

output "azurerm_cdn_endpoint_fqdn" {
  value = azurerm_cdn_endpoint.website.fqdn
}

resource "azurerm_dns_zone" "website" {
  name                = local.domain
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_dns_aaaa_record" "cdn" {
  name                = "@"
  zone_name           = azurerm_dns_zone.website.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = local.one_day_in_seconds
  target_resource_id  = azurerm_cdn_endpoint.website.id
}

output "azurerm_dns_zone_nameservers" {
  value = azurerm_dns_zone.website.name_servers
}

data "azurerm_subscription" "primary" {
}

data "azurerm_client_config" "current" {
}

#data "external" "azure-sync" {
#  depends_on = [
#    azurerm_storage_container.website
#  ]
#
#  program = [
#    "/bin/bash", "bin/azure-website-sync"
#  ]
#
#  query = {
#    folder                = "../../website/html"
#    tenant_id             = var.AZURE_TENANT_ID
#    storage_container_url = "https://${local.domain_without_dot}.blob.core.windows.net/${azurerm_storage_container.website.name}"
#  }
#}

output "azurerm_resource_group" {
  value = azurerm_resource_group.rg.location
}

output "azuread_application_id" {
  value = azuread_application.app.id
}

output "azuread_service_principal_application_tenant_id" {
  value = azuread_service_principal.marcelopinheiro.application_tenant_id
}
