output "vnet_id" {
  description = "Resource ID of the VNet."
  value       = module.vnet.vnet_id
}

output "app_service_hostname" {
  description = "Default hostname of the App Service."
  value       = module.app_service.default_hostname
}

output "mysql_server_name" {
  description = "Name of the MySQL Flexible Server."
  value       = module.mysql.server_name
}

output "storage_account_name" {
  description = "Name of the Storage Account."
  value       = module.storage.storage_account_name
}

output "storage_blob_endpoint" {
  description = "Primary blob service endpoint FQDN."
  value       = module.storage.primary_blob_endpoint
}
