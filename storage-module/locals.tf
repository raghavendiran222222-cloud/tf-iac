locals {
  resource_group_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"

  merged_tags = merge(var.tags, {
    ManagedBy   = "Terraform"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  })

  access_type_map = {
    "private"   = "None"
    "blob"      = "Blob"
    "container" = "Container"
  }

  avm_containers = {
    for name, container in var.blob_containers : name => {
      name          = name
      public_access = lookup(local.access_type_map, container.access_type, "None")
    }
  }

  lock_config = var.enable_resource_lock ? {
    kind = "CanNotDelete"
    name = "lock-${var.storage_account_name}"
  } : null

  diagnostic_settings = var.log_analytics_workspace_id != "" ? {
    "law" = {
      workspace_resource_id = var.log_analytics_workspace_id
    }
  } : {}
}
