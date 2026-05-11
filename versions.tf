terraform {
  required_version = "~> 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.1"
    }
    alz = {
      source  = "azure/alz"
      version = "~> 0.16"
    }
  }

  cloud {
    organization = "bdt-msd"
    workspaces {
      name = "tf-iac-azure-mgt-layer1"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id_management
}

provider "azapi" {}

provider "alz" {}
