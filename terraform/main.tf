provider "aws" {
  version   = "~> 2.12"
  profile   = var.profile
  region    = var.region
}

module "vpc" {
  source   = "./modules/vpc"
  name     = "${var.stage}"
  az_count = 2
}

