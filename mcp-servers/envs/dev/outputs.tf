output "key_vault_name" {
  description = "Name of the Key Vault storing MCP server secrets."
  value       = azurerm_key_vault.this.name
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

# ── GitHub MCP Server ────────────────────────────────────────────────────────

output "github_mcp_hostname" {
  description = "Default hostname of the GitHub MCP App Service."
  value       = module.github_mcp.default_hostname
}

output "github_mcp_endpoint" {
  description = "MCP SSE endpoint URL for the GitHub MCP server."
  value       = module.github_mcp.mcp_endpoint_url
}

# ── HCP Terraform MCP Server ─────────────────────────────────────────────────

output "terraform_mcp_hostname" {
  description = "Default hostname of the HCP Terraform MCP App Service."
  value       = module.terraform_mcp.default_hostname
}

output "terraform_mcp_endpoint" {
  description = "MCP SSE endpoint URL for the HCP Terraform MCP server."
  value       = module.terraform_mcp.mcp_endpoint_url
}

# ── Azure MCP Server ─────────────────────────────────────────────────────────

output "azure_mcp_hostname" {
  description = "Default hostname of the Azure MCP App Service."
  value       = module.azure_mcp.default_hostname
}

output "azure_mcp_endpoint" {
  description = "MCP SSE endpoint URL for the Azure MCP server."
  value       = module.azure_mcp.mcp_endpoint_url
}

output "azure_mcp_principal_id" {
  description = "System-assigned managed identity principal ID of the Azure MCP server."
  value       = module.azure_mcp.identity_principal_id
}
