terraform {
  required_version = "~> 1.9"

  cloud {
    workspaces {
      name = "github-action-test-resource"
    }
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
}
