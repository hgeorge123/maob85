#------------------------------------
# TAGS DEFAULT VALUE PATTERN RESOLVER
#------------------------------------

# This file contains reflection logic to allow vars and locals invocation from string interpolation patterns and references in `default_value_format` and `scope` tag definition.
# Input vars and some local values are "flattened" into a value_resolver map. For each entry:
# the key matches a format like ${var.mandatory_tags.Cost_Center}, which value is the result of the key string interpolation "${var.mandatory_tags.Cost_Center}"
#   Example:
#     value_resolver = {
#       "${local.geo_region}" = "air"
#       "${var.environment}" = "d1"
#       "${var.mandatory_tags.Cost_Center}" = "CC-IACPRD"
#     }

# File has dependencies:
# depends_on = [
#     "${path.module}/main.tf",
#     "${path.module}/tag_definition_loader.tf",
#     "${path.module}/value_resolver*.tf"
# ]

locals {
  value_resolver = local.type_C_tags_not_dependency_with_dependencies_value_resolver # Type C tags is (currently) the last stage for value resolver.

  mandatory_tags_value_resolver = {
    # TAKE a subset of `local.value_resolver` containing only values for mandatory_tags (not input vars neither locals).
    for key in setsubtract(keys(local.value_resolver), keys(local.no_dependency_value_resolver)) :
    key => local.value_resolver[key]
  }
}
