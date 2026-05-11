output "server_id" {
  description = "Resource ID of the MySQL Flexible Server."
  value       = module.mysql.server_id
}

output "server_name" {
  description = "Name of the MySQL Flexible Server."
  value       = module.mysql.server_name
}

output "server_fqdn" {
  description = "Fully qualified domain name of the MySQL Flexible Server."
  value       = module.mysql.server_fqdn
}

output "database_names" {
  description = "List of provisioned database names."
  value       = module.mysql.database_names
}
