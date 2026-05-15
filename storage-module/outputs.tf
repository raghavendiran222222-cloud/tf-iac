output "storage_account_id" {
  description = "ARM resource ID of the Storage Account."
  value       = try(azurerm_storage_account.this[0].id, null)
}

output "storage_account_name" {
  description = "Name of the Storage Account."
  value       = try(azurerm_storage_account.this[0].name, null)
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob service endpoint URL."
  value       = try(azurerm_storage_account.this[0].primary_blob_endpoint, null)
}

output "storage_account_primary_connection_string" {
  description = "Primary connection string for the Storage Account."
  value       = try(azurerm_storage_account.this[0].primary_connection_string, null)
  sensitive   = true
}
