# Plan-only tests — no real Azure credentials needed.
# mock_provider prevents the azurerm/azapi providers from making API calls.

mock_provider "azurerm" {}
mock_provider "azapi" {}

variables {
  subscription_id    = "00000000-0000-0000-0000-000000000001"
  resource_group_name = "rg-dev-mvp-test"
  environment        = "dev"
  location           = "eastus2"
  mysql_admin_password = "TestPassword123!"
  tags = {
    Application         = "mvp-app"
    DevOwner            = "test@example.com"
    BusinessOwner       = "owner@example.com"
    Environment         = "dev"
    DataClassification  = "Internal"
    BusinessCriticality = "Low"
    IACRepository       = "https://github.com/test/repo"
  }
}

run "app_service_output_present" {
  command = plan

  assert {
    condition     = output.app_service_hostname != ""
    error_message = "app_service_hostname output must be non-empty"
  }
}

run "mysql_output_present" {
  command = plan

  assert {
    condition     = output.mysql_server_name != ""
    error_message = "mysql_server_name output must be non-empty"
  }

  assert {
    condition     = output.mysql_server_fqdn != ""
    error_message = "mysql_server_fqdn output must be non-empty"
  }
}

run "storage_output_present" {
  command = plan

  assert {
    condition     = output.storage_account_name != ""
    error_message = "storage_account_name output must be non-empty"
  }
}
