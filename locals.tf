locals {
  parent_resource_id = var.parent_resource_id != "" ? var.parent_resource_id : data.azurerm_client_config.current.tenant_id

  tags = merge(var.default_tags, {
    Layer       = "1"
    ManagedBy   = "Terraform"
    Environment = "mgt"
  })
}
