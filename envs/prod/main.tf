provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

module "vnet" {
  source              = "git::https://github.com/bdtmsd/tf-iac-vnet-module.git?ref=v1.0.0"
  subscription_id     = var.subscription_id
  resource_group_name = var.resource_group_name
  location            = var.location
  vnet_name           = local.vnet_name
  address_space       = var.vnet_address_space
  subnets = {
    (local.subnet_app_name) = {
      address_prefix = "10.20.1.0/24"
      delegation = {
        name    = "delegation-app-service"
        service = "Microsoft.Web/serverFarms"
      }
    }
    (local.subnet_data_name) = {
      address_prefix = "10.20.2.0/24"
      delegation = {
        name    = "delegation-mysql"
        service = "Microsoft.DBforMySQL/flexibleServers"
      }
    }
  }
  tags = local.common_tags
}

module "nsg_app" {
  source              = "git::https://github.com/bdtmsd/tf-iac-nsg-module.git?ref=v1.0.0"
  subscription_id     = var.subscription_id
  resource_group_name = var.resource_group_name
  location            = var.location
  nsg_name            = local.nsg_app_name
  security_rules = {
    "AllowHTTPS" = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
  subnet_associations = {
    (local.subnet_app_name) = module.vnet.subnet_ids[local.subnet_app_name]
  }
  tags = local.common_tags
}

module "app_service" {
  source                = "git::https://github.com/bdtmsd/tf-iac-app-service-module.git?ref=v1.0.0"
  subscription_id       = var.subscription_id
  resource_group_name   = var.resource_group_name
  location              = var.location
  app_service_plan_name = local.asp_name
  app_service_name      = local.app_name
  sku_name              = var.app_sku
  vnet_subnet_id        = module.vnet.subnet_ids[local.subnet_app_name]
  tags                  = local.common_tags
}

resource "azurerm_private_dns_zone" "mysql" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                  = "pdnslink-bdt-mysql-${var.environment}-eus2-001"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  virtual_network_id    = module.vnet.vnet_id
  tags                  = local.common_tags
}

module "mysql" {
  source                 = "git::https://github.com/bdtmsd/tf-iac-mysql-module.git?ref=v1.0.0"
  subscription_id        = var.subscription_id
  resource_group_name    = var.resource_group_name
  location               = var.location
  server_name            = local.mysql_name
  sku_name               = var.mysql_sku
  administrator_login    = var.mysql_admin_username
  administrator_password = var.mysql_admin_password
  delegated_subnet_id    = module.vnet.subnet_ids[local.subnet_data_name]
  private_dns_zone_id    = azurerm_private_dns_zone.mysql.id
  tags                   = local.common_tags
}

module "storage" {
  source                   = "git::https://github.com/bdtmsd/tf-iac-storage-module.git?ref=v1.0.0"
  subscription_id          = var.subscription_id
  resource_group_name      = var.resource_group_name
  location                 = var.location
  storage_account_name     = local.storage_name
  account_replication_type = var.storage_replication
  blob_containers = {
    "uploads" = { access_type = "private" }
    "backups" = { access_type = "private" }
  }
  enable_resource_lock       = var.enable_resource_lock
  log_analytics_workspace_id = var.log_analytics_workspace_id
  tags                       = local.common_tags
}
