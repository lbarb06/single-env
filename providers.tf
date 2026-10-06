terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
  # Local runs use a named profile; CI sets aws_profile="" and uses OIDC credentials
  profile = var.aws_profile != "" ? var.aws_profile : null
}
