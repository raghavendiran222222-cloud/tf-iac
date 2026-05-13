terraform {
  cloud {
    organization = "bdtmsd"

    workspaces {
      name = "alz-landingzones-infra-agent"
      tags = ["non-prod"]
    }
  }
}
