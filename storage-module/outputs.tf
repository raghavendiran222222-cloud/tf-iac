output "storage_account_id" {
  description = "Resource ID of the Storage Account."
  value       = module.storage.resource_id
}

output "storage_account_name" {
  description = "Name of the Storage Account."
  value       = module.storage.name
}

output "primary_blob_endpoint" {
  description = "Primary blob service FQDN."
  value       = try(module.storage.fqdn["blob"], null)
}

output "container_ids" {
  description = "Map of container name to container resource ID."
  value       = { for k, v in module.storage.containers : k => v.id }
}
