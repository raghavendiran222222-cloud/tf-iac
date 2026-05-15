module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"

  suffix = [var.workload, var.env, local.region_abbr]
}

resource "azurerm_storage_account" "this" {
  count               = local.storage_enabled ? 1 : 0
  name                = module.naming.storage_account.name_unique
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = local.merged_tags

  account_tier             = var.storage.account_tier
  account_replication_type = var.storage.account_replication_type

  # Enforce TLS 1.2 as the minimum — disallows older insecure connections
  min_tls_version = "TLS1_2"

  blob_properties {
    versioning_enabled = var.storage.enable_versioning
  }
}

resource "azurerm_storage_container" "this" {
  for_each = local.storage_enabled ? { for c in var.storage.containers : c.name => c } : {}

  name                  = each.key
  storage_account_id    = azurerm_storage_account.this[0].id
  container_access_type = each.value.access_type
}
