# locals {
#   required_tag_keys = toset([
#     for tag_key, tag_definition in yamldecode(file("${path.module}/../assets/tags_definition.yaml")) : tag_key
#     if tag_definition.is_required
#   ])

#   mandatory_tags = tomap({
#     for tag_key, tag_value in var.mandatory_tags : tag_key => tag_value
#     if contains(local.required_tag_keys, tag_key)
#   })
# }

module "mvc" {
  source = "../"
  # version = "~>= 1.0"

  #---------------------------------------------------
  # AWS NAMING
  #---------------------------------------------------
  # entity           = var.entity
  # environment      = var.environment
  # artifact_acronym = var.artifact_acronym
  # app_name         = var.app_name
  # sequence         = var.sequence

  mandatory_tags = var.mandatory_tags

  entity      = "cgs"
  environment = "d1"
  app_name    = "ec2scf"
  function    = "geom"
  sequence    = "999"
  artifact_acronym = "ntc"

  #---------------------------------------------------
  # GLOBAL TAGGING CONVENTION
  #---------------------------------------------------


  #---------------------------------------------------
  # VERY IMPORTANT!!!
  # `parent_resource` is not mandatory in MVC settings, but it has to be included to support TEST CASES related to associated resources.
  #---------------------------------------------------
  parent_resource = {
    artifact_acronym = "ec2"
    sequence = 111

  }
}

output "mvc" {
  value = module.mvc
}
