locals {
  required_tag_keys = toset([
    "APM_functional",
    "CIA",
    "Cost_Center",
    "shared_costs"
  ])

  mandatory_tags = tomap({
    for tag_key, tag_value in var.mandatory_tags : tag_key => tag_value
    if contains(local.required_tag_keys, tag_key)
  })
}

module "mvc" {
  source = "../"
  # version = ">=3.0.0"

  #---------------------------------------
  # GLOBAL NAMING CONVENTION
  #---------------------------------------
  entity      = var.entity
  environment = var.environment
  app_name    = var.app_name
  sequence    = var.sequence

  #---------------------------------------
  # GLOBAL TAGGING CONVENTION
  #---------------------------------------
  mandatory_tags = local.mandatory_tags
}

output "mvc" {
  value = module.mvc
}
