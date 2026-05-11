data "azurerm_client_config" "current" {}

module "alz" {
  source  = "Azure/avm-ptn-alz/azurerm"
  version = "~> 0.11"

  parent_management_group_id = local.parent_management_group_id
  architecture_name          = "alz"
  location                   = var.location
  enable_telemetry           = var.enable_telemetry

  management_group_settings = {
    default_management_group_name = var.root_management_group_id
  }

  subscription_placement = {
    management = {
      subscription_id       = var.subscription_id_management
      management_group_name = "${var.root_management_group_id}-management"
    }
    connectivity = {
      subscription_id       = var.subscription_id_connectivity
      management_group_name = "${var.root_management_group_id}-connectivity"
    }
    identity = {
      subscription_id       = var.subscription_id_identity
      management_group_name = "${var.root_management_group_id}-identity"
    }
  }
}
