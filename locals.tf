locals {
  parent_management_group_id = var.parent_management_group_id != "" ? var.parent_management_group_id : data.azurerm_client_config.current.tenant_id

  tags = merge(var.default_tags, {
    Layer       = "1"
    ManagedBy   = "Terraform"
    Environment = "mgt"
  })
}
