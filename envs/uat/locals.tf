locals {
  resource_group_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"

  common_tags = merge(var.tags, {
    ManagedBy    = "Terraform"
    CreationDate = formatdate("MMDDYYYY", timestamp())
  })

  vnet_name    = "vnet-bdt-mvp-${var.environment}-eus2-001"
  nsg_app_name = "nsg-bdt-mvp-app-${var.environment}-eus2-001"
  asp_name     = "asp-bdt-mvp-${var.environment}-eus2-001"
  app_name     = "app-bdt-mvp-${var.environment}-eus2-001"
  mysql_name   = "mysql-bdt-mvp-${var.environment}-eus2-001"
  storage_name = "stbdtmvp${var.environment}eus2001"

  subnet_app_name  = "snet-bdt-app-${var.environment}-eus2-001"
  subnet_data_name = "snet-bdt-data-${var.environment}-eus2-001"
}
