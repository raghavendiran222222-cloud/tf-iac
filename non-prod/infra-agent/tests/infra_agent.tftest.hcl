# Plan-only tests — no real Azure credentials needed.
# mock_provider prevents the azurerm/azuread/hcp providers from making API calls.

mock_provider "azurerm" {}
mock_provider "azuread" {}
mock_provider "hcp" {}

variables {
  subscription_id          = "00000000-0000-0000-0000-000000000001"
  tenant_id                = "00000000-0000-0000-0000-000000000002"
  environment              = "dev"
  project                  = "mcp"
  location                 = "eastus2"
  hcp_project_id           = "test-project-id"
  hcp_terraform_org        = "test-org"
  apim_publisher_name      = "Test Publisher"
  apim_publisher_email     = "test@example.com"
  copilot_studio_tenant_id = "00000000-0000-0000-0000-000000000003"
}

# ── Core output assertions ────────────────────────────────────────────────────

run "plan_succeeds" {
  command = plan

  assert {
    condition     = output.resource_group_name != ""
    error_message = "resource_group_name output must be non-empty"
  }

  assert {
    condition     = output.key_vault_uri != ""
    error_message = "key_vault_uri output must be non-empty"
  }
}

run "apim_outputs_present" {
  command = plan

  assert {
    condition     = output.apim_gateway_url != ""
    error_message = "apim_gateway_url output must be non-empty"
  }

  assert {
    condition     = output.apim_portal_url != ""
    error_message = "apim_portal_url output must be non-empty"
  }
}

run "copilot_studio_outputs_present" {
  command = plan

  assert {
    condition     = output.copilot_studio_app_client_id != ""
    error_message = "copilot_studio_app_client_id output must be non-empty"
  }

  assert {
    condition     = output.copilot_studio_oauth_token_url != ""
    error_message = "copilot_studio_oauth_token_url output must be non-empty"
  }
}

run "identity_and_cae_outputs_present" {
  command = plan

  assert {
    condition     = output.managed_identity_client_id != ""
    error_message = "managed_identity_client_id output must be non-empty"
  }

  assert {
    condition     = output.container_apps_environment_id != ""
    error_message = "container_apps_environment_id output must be non-empty"
  }
}

run "mcp_api_endpoints_output_present" {
  command = plan

  assert {
    condition     = output.mcp_api_endpoints != null
    error_message = "mcp_api_endpoints output must not be null"
  }
}

# ── Direct resource assertions (config-level values, always known at plan) ────

run "apim_product_config" {
  command = plan

  assert {
    condition     = azurerm_api_management_product.mcp.product_id == "mcp-servers"
    error_message = "APIM product ID must be 'mcp-servers'"
  }

  assert {
    condition     = azurerm_api_management_product.mcp.published == true
    error_message = "APIM MCP product must be published"
  }

  assert {
    condition     = azurerm_api_management_product.mcp.subscription_required == false
    error_message = "APIM MCP product must not require a subscription"
  }
}

run "apim_kv_secrets_names" {
  command = plan

  assert {
    condition     = azurerm_key_vault_secret.github_pat.name == "github-pat"
    error_message = "Key Vault secret for GitHub PAT must be named 'github-pat'"
  }

  assert {
    condition     = azurerm_key_vault_secret.hcp_terraform_token.name == "hcp-terraform-token"
    error_message = "Key Vault secret for HCP Terraform token must be named 'hcp-terraform-token'"
  }
}

run "copilot_studio_oauth_token_url_format" {
  command = plan

  assert {
    condition     = startswith(output.copilot_studio_oauth_token_url, "https://login.microsoftonline.com/")
    error_message = "copilot_studio_oauth_token_url must be a valid Microsoft identity endpoint"
  }
}
