subscription_id     = "00000000-0000-0000-0000-000000000000" # Replace with actual subscription ID
resource_group_name = "rg-bdt-mvp-uat-eus2-001"
location            = "eastus2"
environment         = "uat"

vnet_address_space = ["10.20.0.0/16"]

app_sku   = "P1v3"
mysql_sku = "GP_Standard_D2ds_v4"

mysql_admin_username = "mysqladmin"
# mysql_admin_password — provide via TF_VAR_mysql_admin_password or HashiCorp Vault

storage_replication  = "ZRS"
enable_resource_lock = true

log_analytics_workspace_id = ""

tags = {
  Application         = "BDT MVP"
  DevOwner            = "team@bdtmsd.com"
  BusinessOwner       = "team@bdtmsd.com"
  Environment         = "uat"
  DataClassification  = "Sensitive"
  BusinessCriticality = "Medium"
  IACRepository       = "https://github.com/bdtmsd/tf-iac"
  CostCenter          = ""
  Compliance          = ""
}
