subscription_id     = "00000000-0000-0000-0000-000000000000" # replace with your subscription ID
tenant_id           = "00000000-0000-0000-0000-000000000000" # replace with your tenant ID
resource_group_name = "rg-bdt-mcp-dev-eus2-001"
location            = "eastus2"
environment         = "dev"
tfc_organization    = "bdtmsd"

# Sensitive — do NOT set here. Use environment variables:
#   export TF_VAR_github_pat="ghp_..."
#   export TF_VAR_tfc_token="..."

tags = {
  Application         = "BDT MCP Servers"
  DevOwner            = "platform-team@bdtmsd.com"
  BusinessOwner       = "platform-team@bdtmsd.com"
  Environment         = "dev"
  DataClassification  = "Internal"
  BusinessCriticality = "Low"
  IACRepository       = "https://github.com/bdtmsd/tf-iac"
  CostCenter          = ""
}
