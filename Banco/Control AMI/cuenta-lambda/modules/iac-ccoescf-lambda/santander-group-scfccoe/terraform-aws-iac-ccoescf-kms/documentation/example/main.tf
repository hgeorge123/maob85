
module "this" {
  source = "../"
  # version = ">=3.0.0"

  #---------------------------------------
  # GLOBAL NAMING CONVENTION
  #---------------------------------------
  entity      = var.entity
  environment = var.environment
  app_name    = var.app_name
  function    = var.function
  sequence    = var.sequence

  #---------------------------------------
  # GLOBAL TAGGING CONVENTION
  #---------------------------------------
  mandatory_tags = var.mandatory_tags
  custom_tags    = var.custom_tags

  #---------------------------------------
  # PRODUCT-SPECIFIC VARIABLES
  #---------------------------------------
  alias_name    = var.alias_name
  custom_policy = var.custom_policy
  key_usage     = var.key_usage
  is_enabled    = var.is_enabled
  is_symmetric  = var.is_symmetric
}

output "this" {
  value = module.this
}
