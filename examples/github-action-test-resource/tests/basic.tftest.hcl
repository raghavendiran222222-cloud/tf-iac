run "resource_group_defaults" {
  command = plan

  assert {
    condition     = azurerm_resource_group.this.name == "rg-gha-test"
    error_message = "Resource group name must equal the default value 'rg-gha-test'."
  }

  assert {
    condition     = azurerm_resource_group.this.location == "eastus"
    error_message = "Resource group location must equal the default value 'eastus'."
  }
}

run "resource_group_custom_name" {
  command = plan

  variables {
    resource_group_name = "rg-custom-test"
  }

  assert {
    condition     = azurerm_resource_group.this.name == "rg-custom-test"
    error_message = "Resource group name must reflect the overridden variable."
  }
}

run "required_tags_present" {
  command = plan

  assert {
    condition     = azurerm_resource_group.this.tags["managed-by"] == "terraform"
    error_message = "Tag 'managed-by' must be 'terraform'."
  }

  assert {
    condition     = azurerm_resource_group.this.tags["purpose"] == "github-actions-testing"
    error_message = "Tag 'purpose' must be 'github-actions-testing'."
  }
}
