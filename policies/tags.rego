package main

import rego.v1

# Resources that are exempt from tag enforcement (child resources, role assignments, etc.)
exempt_types := {
  "azurerm_subnet_network_security_group_association",
  "azurerm_role_assignment",
  "azurerm_key_vault_secret",
  "azurerm_api_management_backend",
  "azurerm_api_management_api",
  "azurerm_api_management_product",
  "azurerm_api_management_product_api",
  "azurerm_monitor_diagnostic_setting",
  "azurerm_private_dns_zone_virtual_network_link",
  "azuread_application",
}

required_tags := {"Environment", "IACRepository"}

# Deny top-level Azure resources missing required tags.
deny contains msg if {
  resource := input.resource_changes[_]
  startswith(resource.type, "azurerm_")
  not resource.type in exempt_types
  resource.change.actions[_] in {"create", "update"}
  tags := object.get(resource.change.after, "tags", {})
  missing := required_tags - {k | tags[k]}
  count(missing) > 0
  msg := sprintf(
    "DENY %s is missing required tags: %v",
    [resource.address, missing],
  )
}
