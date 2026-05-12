resource "azurerm_linux_web_app" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = var.service_plan_id

  https_only                    = true
  client_affinity_enabled       = false
  public_network_access_enabled = true

  site_config {
    always_on        = true
    http2_enabled    = true
    minimum_tls_version = "1.2"

    application_stack {
      docker_image_name        = "${var.docker_image}:${var.docker_image_tag}"
      docker_registry_url      = "https://index.docker.io"
    }
  }

  app_settings = merge(var.app_settings, {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    DOCKER_ENABLE_CI                    = "true"
  })

  dynamic "identity" {
    for_each = var.identity_type != "None" ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" ? var.user_assigned_identity_ids : []
    }
  }

  logs {
    http_logs {
      retention_in_days = 7
    }
    application_logs {
      file_system_level = "Information"
    }
  }

  tags = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_linux_web_app.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }
  enabled_log {
    category = "AppServiceConsoleLogs"
  }
  enabled_log {
    category = "AppServiceAppLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_management_lock" "this" {
  count      = var.enable_resource_lock ? 1 : 0
  name       = "lock-${var.name}"
  scope      = azurerm_linux_web_app.this.id
  lock_level = "CanNotDelete"
  notes      = "Resource lock managed by Terraform."
}
