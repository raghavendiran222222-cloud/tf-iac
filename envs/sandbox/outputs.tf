output "vnet_id" {
  description = "Resource ID of the VNet."
  value       = module.vnet.resource_id
}

output "app_service_hostname" {
  description = "Default hostname of the App Service."
  value       = module.app_service.resource_uri
}

output "mysql_server_name" {
  description = "Name of the MySQL Flexible Server."
  value       = module.mysql.server_name
}

output "mysql_server_fqdn" {
  description = "Fully qualified domain name of the MySQL Flexible Server."
  value       = module.mysql.server_fqdn
}

output "storage_account_name" {
  description = "Name of the Storage Account."
  value       = module.storage.name
}

output "storage_blob_endpoint" {
  description = "Primary blob service endpoint FQDN."
  value       = try(module.storage.fqdn["blob"], null)
}
