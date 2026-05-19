# Plan-only tests — no real Azure credentials needed.
# mock_provider prevents the azurerm/azuread/hcp providers from making API calls.

mock_provider "azurerm" {}
mock_provider "azuread" {}
mock_provider "hcp" {}

variables {
  subscription_id         = "00000000-0000-0000-0000-000000000001"
  tenant_id               = "00000000-0000-0000-0000-000000000002"
  environment             = "dev"
  project                 = "mcp"
  location                = "eastus2"
  hcp_project_id          = "test-project-id"
  hcp_terraform_org       = "test-org"
  apim_publisher_name     = "Test Publisher"
  apim_publisher_email    = "test@example.com"
  copilot_studio_tenant_id = "00000000-0000-0000-0000-000000000003"
}

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

run "apim_output_present" {
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
