resource "azurerm_mysql_flexible_server" "this" {
  name                = var.server_name
  resource_group_name = var.resource_group_name
  location            = var.location

  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password

  sku_name = var.sku_name
  version  = var.mysql_version

  storage {
    size_gb = var.storage_size_gb
  }

  backup_retention_days = var.backup_retention_days

  delegated_subnet_id = var.delegated_subnet_id != "" ? var.delegated_subnet_id : null
  private_dns_zone_id = var.private_dns_zone_id != "" ? var.private_dns_zone_id : null

  tags = var.tags

  lifecycle {
    ignore_changes = [zone, high_availability[0].standby_availability_zone]
  }
}

resource "azurerm_mysql_flexible_database" "this" {
  for_each = var.databases

  name                = each.key
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.this.name
  charset             = each.value.charset
  collation           = each.value.collation
}

resource "azurerm_management_lock" "this" {
  count = var.enable_resource_lock ? 1 : 0

  name       = "lock-${var.server_name}"
  scope      = azurerm_mysql_flexible_server.this.id
  lock_level = "CanNotDelete"
}
