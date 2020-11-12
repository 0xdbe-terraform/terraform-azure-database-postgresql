resource "random_integer" "main" {
  min     = 1
  max     = 999
}

resource "random_password" "admin" {
    length           = 30
    special          = true
    override_special = "_%?!#()-[]<>,;*@="
    min_upper        = 1
    min_lower        = 1
    min_numeric      = 1
    min_special      = 1
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

  version                      = var.psql_server_version
  
  ssl_enforcement_enabled          = true
  ssl_minimal_tls_version_enforced = "TLS1_2"

}

resource "azurerm_postgresql_firewall_rule" "all" {
  name                = "all"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.main.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

resource "azuread_group" "db_admin" {
  name = "group-${lower(var.application_short_name)}-${var.application_environment}-psql-${length(var.psql_server_purpose) > 0 ? "${var.psql_server_purpose}-" : ""}admin"
}


resource "azuread_group_member" "db_admin" {
  count             = length(var.psql_server_administrators)
  group_object_id   = azuread_group.db_admin.id
  member_object_id  = element(var.psql_server_administrators, count.index)
}

resource "azurerm_postgresql_active_directory_administrator" "main" {
  server_name         = azurerm_postgresql_server.main.name
  resource_group_name = var.resource_group_name
  tenant_id           = var.azure_tenant_id
  object_id           = azuread_group.db_admin.object_id
  login               = "adm1n157r470r44D"
}

resource "azuread_group" "db_user" {

  name  = "group-${lower(var.application_short_name)}-${var.application_environment}-psql-${length(var.psql_server_purpose) > 0 ? "${var.psql_server_purpose}-" : ""}user"
  
  # Local exec is used because Terraform Provider for Postgresql doesn't support "SET" command
  provisioner "local-exec" {
    working_dir = "${path.module}/"
    command     = "./postgresql_setup.sh"
    interpreter = ["/bin/bash"]
    environment = {
      PGDATABASE    = "postgres"
      PGHOST        = "${azurerm_postgresql_server.main.name}.postgres.database.azure.com"
      PGUSER        = "${azurerm_postgresql_active_directory_administrator.main.login}@${azurerm_postgresql_server.main.name}"
      PGSSLMODE     = verify-full
      PGSSLROOTCERT = BaltimoreCyberTrustRoot.crt.pem
      GROUP_NAME    = self.name
    }
  }
}

resource "azuread_group_member" "db_user" {
  count             = length(var.psql_server_users)
  group_object_id   = azuread_group.db_user.id
  member_object_id  = element(var.psql_server_users, count.index)
}

resource "azurerm_postgresql_database" "main" {
  for_each            = var.database_name
  name                = each.key
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.main.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}