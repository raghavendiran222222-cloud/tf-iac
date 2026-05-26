terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  cloud {
    organization = "bdtmsd"
    workspaces {
      name = "github-action-test-resource"
    }
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.71"
    }
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
}
