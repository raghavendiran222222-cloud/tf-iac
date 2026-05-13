output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "apim_gateway_url" {
  description = "APIM gateway URL — use as the base URL in Copilot Studio custom connectors"
  value       = module.apim.apim_gateway_url
}

output "apim_portal_url" {
  description = "APIM developer portal URL"
  value       = module.apim.developer_portal_url
}

output "mcp_api_endpoints" {
  description = "APIM endpoint per MCP server (for Copilot Studio connector configuration)"
  value = {
    github    = "${module.apim.apim_gateway_url}/github"
    azure     = "${module.apim.apim_gateway_url}/azure"
    terraform = "${module.apim.apim_gateway_url}/terraform"
  }
}

output "copilot_studio_app_client_id" {
  description = "OAuth2 App Registration client ID — set as the audience in Copilot Studio connector auth"
  value       = azuread_application.copilot_studio.client_id
}

output "copilot_studio_oauth_token_url" {
  description = "OAuth2 token endpoint for Copilot Studio connector auth configuration"
  value       = "https://login.microsoftonline.com/${var.copilot_studio_tenant_id}/oauth2/v2.0/token"
}

output "key_vault_uri" {
  description = "Key Vault URI — use for manual secret rotation"
  value       = module.key_vault.uri
}

output "managed_identity_client_id" {
  description = "UAMI client ID — set as AZURE_CLIENT_ID in Azure MCP if running locally"
  value       = module.uami.client_id
}

output "container_apps_environment_id" {
  description = "Container Apps Environment resource ID"
  value       = module.container_apps_environment.resource_id
}
