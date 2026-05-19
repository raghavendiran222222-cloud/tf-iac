package main

import rego.v1

# Deny any storage account that allows public network access.
# Azure Policy enforces this at runtime; this rule catches it at PR time.
deny contains msg if {
  resource := input.resource_changes[_]
  resource.type == "azurerm_storage_account"
  resource.change.actions[_] in {"create", "update"}
  resource.change.after.public_network_access_enabled == true
  msg := sprintf(
    "DENY storage account %q must not allow public network access (public_network_access_enabled = true)",
    [resource.address],
  )
}

# Deny storage accounts missing infrastructure encryption.
deny contains msg if {
  resource := input.resource_changes[_]
  resource.type == "azurerm_storage_account"
  resource.change.actions[_] in {"create", "update"}
  not resource.change.after.infrastructure_encryption_enabled
  msg := sprintf(
    "DENY storage account %q must enable infrastructure encryption",
    [resource.address],
  )
}
