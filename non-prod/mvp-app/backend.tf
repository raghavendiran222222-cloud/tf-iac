terraform {
  cloud {
    organization = "bdtmsd"

    workspaces {
      name = "alz-landingzones-infra"
      tags = ["non-prod"]
    }
  }
}
