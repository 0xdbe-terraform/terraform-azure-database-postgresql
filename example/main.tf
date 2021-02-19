provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {
}

locals {
  azure_location          = "eastus"
  application_full_name   = "Hello World"
  application_short_name  = "HW"
  application_environment = "dev"
}

module "azure_ressource_group" {
  source                  = "git::https://github.com/0xdbe-terraform/terraform-azure-resource-group.git?ref=v2.0.1"
  azure_location          = local.azure_location
  application_full_name   = local.application_full_name
  application_short_name  = local.application_short_name
  application_environment = local.application_environment
}

# Service Principal used by Azure DevOps
module "azure_ad_sp_azdo" {
  source                    = "git::https://github.com/0xdbe-terraform/terraform-azure-ad-service-principal.git?ref=v2.0.2"
  application_full_name     = local.application_full_name
  application_environment   = local.application_environment
  service_principal_purpose = "azdo"
}

# Service Principal used by application
module "azure_ad_sp_app" {
  source                    = "git::https://github.com/0xdbe-terraform/terraform-azure-ad-service-principal.git?ref=v2.0.2"
  application_full_name     = local.application_full_name
  application_environment   = local.application_environment
  service_principal_purpose = "app"
}

module "azure_database_postgresql" {
  source                     = "git::https://github.com/0xdbe-terraform/terraform-azure-database-postgresql.git?ref=v2.0.7"
  azure_tenant_id            = data.azurerm_client_config.current.tenant_id
  azure_location             = local.azure_location
  application_full_name      = local.application_full_name
  application_short_name     = local.application_short_name
  application_environment    = local.application_environment
  resource_group_name        = module.azure_ressource_group.name
  psql_server_administrators = [data.azurerm_client_config.current.object_id, module.azure_ad_sp_azdo.service_principal_id]
  psql_server_users          = [module.azure_ad_sp_app.service_principal_id]
}
