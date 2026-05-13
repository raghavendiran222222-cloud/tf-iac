# Example: consume the infra-agent root module
# This is for reference only — the root module is not a reusable child module.
# Deploy directly via `terraform apply` from non-prod/infra-agent/.

module "infra_agent" {
  source = "../"

  subscription_id          = "00000000-0000-0000-0000-000000000000"
  tenant_id                = "00000000-0000-0000-0000-000000000000"
  location                 = "eastus2"
  project                  = "mcp"
  environment              = "dev"
  hcp_project_id           = "00000000-0000-0000-0000-000000000000"
  hcp_vault_app_name       = "mcp-servers"
  hcp_terraform_org        = "my-hcp-org"
  apim_publisher_name      = "Platform Team"
  apim_publisher_email     = "platform@example.com"
  copilot_studio_tenant_id = "00000000-0000-0000-0000-000000000000"
}
