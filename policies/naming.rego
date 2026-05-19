package main

import rego.v1

# Resources where names are Azure-managed or follow different conventions
naming_exempt_types := {
  "azurerm_subnet_network_security_group_association",
  "azurerm_role_assignment",
  "azurerm_private_dns_zone_virtual_network_link",
  "azurerm_monitor_diagnostic_setting",
  "azuread_application",
  "azurerm_key_vault_secret",
}

# Warn (not deny) when a resource name does not contain a hyphen — flat names
# like "storageaccount1" suggest an ad-hoc name rather than a structured one.
# Policy is advisory to catch obvious violations without blocking valid AVM defaults.
warn contains msg if {
  resource := input.resource_changes[_]
  startswith(resource.type, "azurerm_")
  not resource.type in naming_exempt_types
  resource.change.actions[_] in {"create", "update"}
  name := object.get(resource.change.after, "name", "")
  name != ""
  not contains(name, "-")
  msg := sprintf(
    "WARN %s: resource name %q has no hyphens — expected structured name like <env>-<project>-<suffix>",
    [resource.address, name],
  )
}
