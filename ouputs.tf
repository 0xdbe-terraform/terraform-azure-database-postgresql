output "name" {
  value = azurerm_postgresql_server.main.name
}

output "login" {
  value = azurerm_postgresql_active_directory_administrator.main.login
}