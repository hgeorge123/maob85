terraform {
  required_version = ">= 0.15"
}

locals {
  allowed_regions = {
    us-east-2      = "ae2"
    us-east-1      = "ae1"
    us-west-1      = "aw1"
    us-west-2      = "aw2"
    ap-east-1      = "ap1"
    ap-south-1     = "ap2"
    ap-northeast-3 = "ap3"
    ap-northeast-2 = "ap4"
    ap-southeast-1 = "ap5"
    ap-southeast-2 = "ap6"
    ap-northeast-1 = "ap7"
    ca-central-1   = "acn"
    cn-north-1     = "abj"
    cn-northwest-1 = "anx"
    eu-central-1   = "aft"
    eu-west-1      = "air"
    eu-west-2      = "ald"
    eu-west-3      = "apa"
    eu-north-1     = "ask"
    me-south-1     = "aba"
    sa-east-1      = "abr"
  }

  aws_region = var.region
  geo_region = lookup(local.allowed_regions, local.aws_region)

  # Check whether the naming and tagging is going to be applied to an associated (child) resource.
  is_associated_resource = var.parent_resource != null
}
