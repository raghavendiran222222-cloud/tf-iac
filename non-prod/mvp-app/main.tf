# ── Tier 1: Networking ────────────────────────────────────────────────────────

module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.17.1"

  name          = local.vnet_name
  location      = var.location
  parent_id     = local.resource_group_id
  address_space = toset(var.vnet_address_space)

  subnets = {
    (local.subnet_app_name) = {
      name             = local.subnet_app_name
      address_prefixes = ["10.30.1.0/24"]
      delegations = [{
        name = "delegation-app-service"
        service_delegation = {
          name = "Microsoft.Web/serverFarms"
        }
      }]
    }
    (local.subnet_data_name) = {
      name             = local.subnet_data_name
      address_prefixes = ["10.30.2.0/24"]
      delegations = [{
        name = "delegation-mysql"
        service_delegation = {
          name = "Microsoft.DBforMySQL/flexibleServers"
        }
      }]
    }
  }

  enable_telemetry = false
  tags             = local.common_tags
}

module "nsg_app" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.1"

  name                = local.nsg_app_name
  resource_group_name = var.resource_group_name
  location            = var.location

  security_rules = {
    "AllowHTTPS" = {
      name                       = "AllowHTTPS"
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

  enable_telemetry = false
  tags             = local.common_tags
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = module.vnet.subnets[local.subnet_app_name].resource_id
  network_security_group_id = module.nsg_app.resource_id
}

# ── Tier 2: Application ───────────────────────────────────────────────────────

module "app_service_plan" {
  source  = "Azure/avm-res-web-serverfarm/azurerm"
  version = "2.0.4"

  name      = local.asp_name
  parent_id = local.resource_group_id
  location  = var.location
  os_type   = "Linux"
  sku_name  = var.app_sku

  enable_telemetry = false
  tags             = local.common_tags
}

module "app_service" {
  source  = "Azure/avm-res-web-site/azurerm"
  version = "0.22.0"

  name                      = local.app_name
  parent_id                 = local.resource_group_id
  location                  = var.location
  kind                      = "webapp"
  os_type                   = "Linux"
  service_plan_resource_id  = module.app_service_plan.resource_id
  virtual_network_subnet_id = module.vnet.subnets[local.subnet_app_name].resource_id

  enable_telemetry = false
  tags             = local.common_tags
}

# ── Tier 2: Data ─────────────────────────────────────────────────────────────

resource "azurerm_private_dns_zone" "mysql" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                  = "pdnslink-bdt-mysql-${var.environment}-eus2-001"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  virtual_network_id    = module.vnet.resource_id
  tags                  = local.common_tags
}

module "mysql" {
  source  = "Azure/avm-res-dbformysql-flexibleserver/azurerm"
  version = "0.1.6"

  name                = local.mysql_name
  resource_group_name = var.resource_group_name
  location            = var.location

  administrator_login    = var.mysql_admin_username
  administrator_password = var.mysql_admin_password
  sku_name               = var.mysql_sku
  mysql_version          = "8.0.21"

  delegated_subnet_id = module.vnet.subnets[local.subnet_data_name].resource_id
  private_dns_zone_id = azurerm_private_dns_zone.mysql.id

  databases = {
    "appdb" = { name = "appdb", charset = "utf8mb4", collation = "utf8mb4_unicode_ci" }
  }

  lock = var.enable_resource_lock ? { kind = "CanNotDelete" } : null

  geo_redundant_backup_enabled = false
  enable_telemetry             = false
  tags                         = local.common_tags
}

module "storage" {
  source = "git::https://github.com/raghavendiran222222-cloud/tf-iac.git//storage-module?ref=storage-module-v0.1.0"

  subscription_id      = var.subscription_id
  resource_group_name  = var.resource_group_name
  storage_account_name = local.storage_name
  location             = var.location

  account_replication_type = var.storage_replication

  blob_containers = {
    "uploads" = { access_type = "private" }
    "backups" = { access_type = "private" }
  }

  enable_resource_lock       = var.enable_resource_lock
  log_analytics_workspace_id = var.log_analytics_workspace_id

  tags = {
    Application = var.tags.Application
    Owner       = var.tags.DevOwner
    Environment = var.tags.Environment
    CostCenter  = coalesce(var.tags.CostCenter, "unset")
  }
}
