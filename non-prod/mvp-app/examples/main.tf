# Example: consume the mvp-app root module
# This is for reference only — the root module is not a reusable child module.
# Deploy directly via `terraform apply` from non-prod/mvp-app/.

module "mvp_app" {
  source = "../"

  subscription_id      = "00000000-0000-0000-0000-000000000000"
  resource_group_name  = "rg-bdt-mvp-sandbox-eus2-001"
  location             = "eastus2"
  environment          = "sandbox"
  vnet_address_space   = ["10.30.0.0/16"]
  app_sku              = "B1"
  mysql_sku            = "B_Standard_B1ms"
  mysql_admin_username = "mysqladmin"
  mysql_admin_password = "REPLACE_VIA_TF_VAR"

  tags = {
    Application         = "BDT MVP"
    DevOwner            = "team@bdtmsd.com"
    BusinessOwner       = "team@bdtmsd.com"
    Environment         = "sandbox"
    DataClassification  = "Internal"
    BusinessCriticality = "Low"
    IACRepository       = "https://github.com/bdtmsd/tf-iac"
  }
}
