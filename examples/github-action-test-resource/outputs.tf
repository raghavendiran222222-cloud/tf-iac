output "resource_group_name" {
  description = "Name of the deployed resource group."
  value       = azurerm_resource_group.this.name
}

output "resource_group_id" {
  description = "Full resource ID of the resource group."
  value       = azurerm_resource_group.this.id
}
