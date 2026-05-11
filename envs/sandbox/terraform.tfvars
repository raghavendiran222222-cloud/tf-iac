subscription_id     = "00000000-0000-0000-0000-000000000000" # Replace with actual subscription ID
resource_group_name = "rg-bdt-mvp-sandbox-eus2-001"
location            = "eastus2"
environment         = "sandbox"

vnet_address_space = ["10.30.0.0/16"]

app_sku   = "B1"
mysql_sku = "B_Standard_B1ms"

mysql_admin_username = "mysqladmin"
# mysql_admin_password — provide via TF_VAR_mysql_admin_password or HashiCorp Vault

storage_replication  = "LRS"
enable_resource_lock = false

log_analytics_workspace_id = ""

tags = {
  Application         = "BDT MVP"
  DevOwner            = "team@bdtmsd.com"
  BusinessOwner       = "team@bdtmsd.com"
  Environment         = "sandbox"
  DataClassification  = "Internal"
  BusinessCriticality = "Low"
  IACRepository       = "https://github.com/bdtmsd/tf-iac"
  CostCenter          = ""
  Compliance          = ""
}
