provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

module "storage" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.8"

  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
  location            = var.location

  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind

  https_traffic_only_enabled = var.enable_https_traffic_only
  min_tls_version            = var.min_tls_version

  containers                          = local.avm_containers
  lock                                = local.lock_config
  diagnostic_settings_storage_account = local.diagnostic_settings
  enable_telemetry                    = false
  tags                                = local.merged_tags
}
