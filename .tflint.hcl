plugin "azurerm" {
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
  version = "0.27.0"
  enabled = true
}

config {
  # Don't recurse into AVM child modules — they are externally maintained
  call_module_type = "none"
}
