terraform {
  cloud {
    organization = "<organization-name>"

    workspaces {
      name = "infra-agent"
    }
  }
}
