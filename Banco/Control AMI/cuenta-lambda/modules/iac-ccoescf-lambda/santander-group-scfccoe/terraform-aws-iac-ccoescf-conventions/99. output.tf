#--------
# NAMING
#--------
output "product_name" {
  description = "Calculated name of the target resource."
  value       = lower(lookup(local.tags, "Name", null))
}

output "geo_region" {
  description = "Resolved geographical region acronym."
  value       = local.geo_region
}

output "aws_region" {
  description = "Name of the provider selected region."
  value       = local.aws_region
}

output "naming_convention_regex_pattern" {
  description = "Regex pattern to determine whether a resource name matches SCF naming convention."
  value       = "^[[:alnum:]]{24}(?:-[[:alpha:]]{3}[[:digit:]]{2})?$" # TODO: Get from 'Name' tag definition when validation pattern is available.
}

#--------
# TAGGING
#--------
locals {
  tags = merge(
    var.custom_tags,
    local.mandatory_tags
  )
}

output "tags" {
  description = "Map of string with Tags to be declared in target resource."
  value       = local.tags
}

# output "loaded_tags_definition" {
#   description = "Every tag loaded from Yaml tags definition file."
#   value       = local.loaded_tags_definition
# }

# output "scope_tags_definition" {
#   description = "Tag definitions matching the given scopes to be validated."
#   value       = local.tags_definition
# }
