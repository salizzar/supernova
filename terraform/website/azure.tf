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

  #app_roles = [
  #  data.azurerm_role_definition.blob-data-owner.id
  #]

  #oauth2_permission_scopes = [
  #  {
  #    id = "/subscriptions/${azurerm_subscription.subscription.alias}/resourceGroups/${azurerm_resource_group.rg.name}"
  #  }
  #]
}

data "azurerm_subscription" "primary" {
}

data "azurerm_client_config" "client" {
}

#data "azurerm_role_definition" "blob-data-owner" {
#  role_definition_id = "b7e6dc6d-f1e8-4753-8033-0f276bb0955b" # "b24988ac-6180-42a0-ab88-20f7382dd24c"
#  scope              = data.azurerm_subscription.primary.id
#}

#resource "azurerm_role_definition" "blob-data-owner" {
#  role_definition_id = "b7e6dc6d-f1e8-4753-8033-0f276bb0955b" # "00000000-0000-0000-0000-000000000000"
#  name               = "marcelopinheiro-co_blob-data-owner"
#  scope              = data.azurerm_subscription.primary.id
#
#  permissions {
#    actions     = ["Microsoft.Resources/subscriptions/resourceGroups/read"]
#    not_actions = []
#  }
#
#  assignable_scopes = [
#    data.azurerm_subscription.primary.id,
#  ]
#}


#resource "azurerm_role_assignment" "assignment" {
#  name               = azurerm_role_definition.blob-data-owner.role_definition_id
#  scope              = data.azurerm_subscription.primary.id
#  role_definition_id = azurerm_role_definition.blob-data-owner.role_definition_id
#  principal_id       = data.azurerm_client_config.client.object_id
#}

resource "azurerm_storage_account" "website" {
  name                     = local.domain_without_dot
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

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

resource "azurerm_storage_container" "website" {
  name                  = "website"
  storage_account_name  = azurerm_storage_account.website.name
  container_access_type = "private"
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
#    folder                = "../../website/"
#    tenant_id             = var.AZURE_TENANT_ID
#    storage_container_url = "https://${local.domain_without_dot}.blob.core.windows.net/${azurerm_storage_container.website.name}"
#  }
#}

#data "external" "compress-website" {
#  program = [
#    "/bin/bash", "bin/compress"
#  ]
#
#  query = {
#    zip_file_path = "../../website.zip"
#
#    zip_folder_files = join(" ", [
#      "../../website/index.html",
#      "../../website/404.html",
#      "../../website/styes",
#      "../../website/images"
#    ])
#  }
#}
#
#resource "azurerm_storage_blob" "website" {
#  name                   = local.domain_without_dot
#  storage_account_name   = azurerm_storage_account.marcelopinheiro.name
#  storage_container_name = azurerm_storage_container.marcelopinheiro.name
#  type                   = "Block"
#  source                 = data.external.compress-website.result["zip_file_path"]
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

#output "azurerm_storage_blob_url" {
#  value = azurerm_storage_blob.website.url
#}
