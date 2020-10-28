resource "random_integer" "main" {
  min     = 1
  max     = 999
}

resource "random_password" "admin" {
  length           = 30
  special          = true
}

resource "azurerm_postgresql_server" "main" {

  name                = "psql-server-${lower(substr("${var.application_short_name}-${length(var.psql_server_purpose) > 0 ? "${var.psql_server_purpose}-" : ""}${var.application_environment}",0,45))}-${format("%000d",random_integer.main.result)}"
  location            = var.azure_location
  resource_group_name = var.resource_group_name
  
  sku_name                     = "B_Gen5_1"
  storage_mb                   = 5120
  auto_grow_enabled            = false
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  administrator_login          = "adm1n157r470r"
  administrator_login_password = random_password.admin.result

  version                      = "11"
  
  ssl_enforcement_enabled          = true
  ssl_minimal_tls_version_enforced = "TLS1_2"

}

resource "azurerm_postgresql_firewall_rule" "all" {
  name                = "all"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.main.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "2555.255.255.255"
}

resource "azuread_group" "db_admin" {
  name = "group-${replace(title(var.application_full_name)," ","")}-${var.application_environment}-psql-${length(var.psql_server_purpose) > 0 ? "${var.psql_server_purpose}-" : ""}-admin"
}

resource "azuread_group_member" "db_admin" {
  for_each          = var.psql_server_administrators_id
  group_object_id   = azuread_group.db_admin.id
  member_object_id  = each.key
}

resource "azurerm_postgresql_active_directory_administrator" "main" {
  server_name         = azurerm_postgresql_server.main.name
  resource_group_name = var.resource_group_name
  tenant_id           = var.azure_tenant_id
  object_id           = azuread_group.db_admin.object_id
  login               = "adm1n157r470r44D"
}
