#------------------------------------
# TAGS DEFAULT VALUE PATTERN RESOLVER
#------------------------------------

# This file contains reflection logic to allow vars and locals invocation from string interpolation patterns and references in `default_value` format and `scope` tag definition.
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
#     "${path.module}/tag_definition_loader.tf"
# ]

# # Uncomment next block just when needed for debugging purposes:
# output "locals" {
#   description = "Just for debugging purposes. Do NOT include in module release."
#   value = {
#     # dependencies                                                        = local.tag_definition_dependencies
#     var                                                                 = local.var
#     local                                                               = local.local
#     no_dependency_value_resolver                                        = local.no_dependency_value_resolver
#     type_A_tags_with_no_dependencies_default_value_fulfilled_conditions = local.type_A_tags_with_no_dependencies_default_value_fulfilled_conditions
#     type_A_tags_with_no_dependencies_value_resolver                     = local.type_A_tags_with_no_dependencies_value_resolver
#     # type_B_tags_dependency_with_dependencies_value_resolver             = local.mandatory_type_B_tags_dependency_with_dependencies_value_resolver
#     type_C_tags_not_dependency_with_dependencies_value_resolver         = local.type_C_tags_not_dependency_with_dependencies_value_resolver
#     value_resolver                                                      = local.value_resolver
#     # value_resolver_2                                                      = local.value_resolver_2
#   }
# }
locals {

  input_vars = merge(
    # List input variables to be referenced in tag definition string interpolations.
    {
      # Flatten `var.parent_resource`
      for key, value in coalesce(
        var.parent_resource,
        {
          artifact_acronym = null
          sequence         = null
        }
      ) : "parent_resource.${key}" => value
    },
    {
      # List input variables
      entity           = lower(tostring(var.entity))
      environment      = tostring(var.environment)
      artifact_acronym = tostring(var.artifact_acronym)
      app_name         = tostring(var.app_name)
      function         = tostring(var.function)
      sequence         = tostring(var.sequence)
      entity_upper     = upper(tostring(var.entity))
      # Currently, sequence is not being restricted, even when referred for an associated/child resource.
      # sequence = tostring(
      #   local.is_associated_resource
      #   ? substr(coalesce(var.sequence, 1), -2, -1) # Take only the last 2 digits if the sequence belongs to an associated (child) resource.
      #   : var.sequence
      # )
  })

  var = merge(
    {
      # Flatten local.input_vars to allow accessing them this way: `local.var["${var.custom_tags.My_tag}"]` or `local.var["${var.entity}"]`
      for key, value in local.input_vars : "$${var.${key}}" => {
        key   = key,
        value = value
      }
    },
    {
      # Flatten `var.custom_tags`
      for key, value in coalesce(var.custom_tags, {}) : "$${var.custom_tags.${key}}" => {
        key   = key,
        value = value
      }
    }
  )

  local_vars = {
    # List supported local variables to be referenced in tag definition string interpolations.
    aws_region             = local.aws_region
    geo_region             = local.geo_region
    is_associated_resource = local.is_associated_resource
  }

  local = {
    # Flatten local.local_vars to allow access them in this way: `local.local["${local.function}"]`
    for key, value in local.local_vars : "$${local.${key}}" => {
      key   = key,
      value = value
    }
  }

  # Interpolated string map to resolve input vars or local variable values.
  no_dependency_value_resolver = tomap(merge(
    local.var,
    local.local
  ))
  

}
