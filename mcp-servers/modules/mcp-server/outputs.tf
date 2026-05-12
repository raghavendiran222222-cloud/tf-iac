output "id" {
  description = "The resource ID of the App Service."
  value       = azurerm_linux_web_app.this.id
}

output "name" {
  description = "The name of the App Service."
  value       = azurerm_linux_web_app.this.name
}

output "default_hostname" {
  description = "The default hostname of the App Service."
  value       = azurerm_linux_web_app.this.default_hostname
}

output "mcp_endpoint_url" {
  description = "The HTTPS MCP endpoint URL for this server."
  value       = "https://${azurerm_linux_web_app.this.default_hostname}/sse"
}

output "identity_principal_id" {
  description = "The principal ID of the system-assigned managed identity. Null when identity_type is None or UserAssigned."
  value       = var.identity_type == "SystemAssigned" ? azurerm_linux_web_app.this.identity[0].principal_id : null
}
