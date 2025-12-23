data "aws_caller_identity" "current" {}

data "aws_organizations_organization" "org" {}

data "aws_region" "current" {}

data "aws_ami" "source_ami" {
  for_each = var.image_builder_config

  most_recent = true
  filter {
    name   = "image-id"
    values = [each.value.image_builder_ami]
  }
}