terraform {
  cloud {
    organization = "<organization-name>"

    workspaces {
      name = "mvp-app"
    }
  }
}
