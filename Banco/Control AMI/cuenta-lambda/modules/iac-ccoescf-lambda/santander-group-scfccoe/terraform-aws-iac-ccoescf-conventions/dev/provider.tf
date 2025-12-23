terraform {
  required_version = ">= 0.15"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
      # version = "~> 4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.1.1"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-1"
}
