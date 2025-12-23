terraform {
   required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "aws" {
  region = "us-east-2"
  alias = "us-east-2"
}