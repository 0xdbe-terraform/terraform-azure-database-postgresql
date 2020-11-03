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
  source                  = "git::https://github.com/0xdbe-terraform/terraform-azure-resource-group.git?ref=v2.0.0"
  azure_location          = local.azure_location
  application_full_name   = local.application_full_name
  application_short_name  = local.application_short_name
  application_environment = local.application_environment
}

module "azure_ad_sp" {
  source                    = "git::https://github.com/0xdbe-terraform/terraform-azure-ad-service-principal.git?ref=v2.0.1"
  application_full_name     = local.application_full_name
  application_environment   = local.application_environment
  service_principal_purpose = "azdo"
}

module "azure_database_postgresql" {
  #source                     = "git::https://github.com/0xdbe-terraform/terraform-azure-database-postgresql.git?ref=v2.0.1"
  source                     = "../"
  azure_tenant_id            = data.azurerm_client_config.current.tenant_id
  azure_location             = local.azure_location
  application_full_name      = local.application_full_name
  application_short_name     = local.application_short_name
  application_environment    = local.application_environment
  resource_group_name        = module.azure_ressource_group.name
  psql_server_administrators = [data.azurerm_client_config.current.object_id, module.azure_ad_sp.service_principal_id]
  psql_server_users          = ["f592d48c-f782-4b5f-a3c1-4aebce6e1cdb"]
  depends_on                 = [module.azure_ad_sp]
}
