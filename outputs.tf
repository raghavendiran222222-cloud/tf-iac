output "server_id" {
  description = "Resource ID of the MySQL Flexible Server."
  value       = azurerm_mysql_flexible_server.this.id
}

output "server_name" {
  description = "Name of the MySQL Flexible Server."
  value       = azurerm_mysql_flexible_server.this.name
}

output "server_fqdn" {
  description = "Fully qualified domain name of the MySQL Flexible Server."
  value       = azurerm_mysql_flexible_server.this.fqdn
}

output "database_names" {
  description = "List of database names provisioned on the server."
  value       = keys(var.databases)
}
