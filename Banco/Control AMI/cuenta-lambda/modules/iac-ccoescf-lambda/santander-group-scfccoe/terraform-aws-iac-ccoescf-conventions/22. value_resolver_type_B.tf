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
  #-------------------------------------
  # TAGS DEFAULT VALUE PATTERN RESOLVERS
  #-------------------------------------
  #   Example of default value object input in tag definition:
  #   default_value_definition = [
  #     {
  #       condition = {
  #         string_equals = {
  #           "${var.entity}" = [ # String interpolation for "${var.entity}" shall be replaced with the `var.entity` input value. Then, if `var.entity` is one of the expected values, this condition is fulfilled.
  #             "IACPRD",
  #             "SCFWEU"
  #           ]
  #         }
  #       }
  #       format = [
  #         "%s-%s",
  #         "${var.custom_tags.prefix}", # String interpolation for "${var.custom_tags.prefix}" shall be replaced with the given value.
  #         "cc001"
  #       ]
  #     }
  #   ]
  #
  #   Example of default value object output:
  #   default_value = [
  #     {
  #       condition = {
  #         string_equals = [
  #           {
  #             condition_key = "IACPRD"
  #             condition_values = [
  #               "IACPRD",
  #               "SCFWEU"
  #             ]
  #         }]
  #       }
  #       format = [
  #         "%s-%s",
  #         "myCustomPrefix",
  #         "cc001"
  #       ]
  #     }
  #   ]

  type_B_tags_dependency_with_dependencies_definition = {
    # [STAGE 2.0] REPLACE `default_value_definition` and `scope_definition` tokenized arguments.
    for tag_name, tag_definition in local.tags_definition_input_dependency_with_dependencies :
    tag_name => merge(
      tag_definition, # KEEP the other properties as they were previously set.
      {
        default_value = [ # BUILD `default_value` with argument replacements (when tokenized).
          for default_value_definition in tag_definition.default_value_definition :
          {
            index                = default_value_definition.index
            condition_definition = default_value_definition.condition
            condition = {
              for condition_operand, condition_block in default_value_definition.condition :
              "${condition_operand}" => [
                for condition_key, condition_values in condition_block : {
                  condition_key = (
                    # CHECK whether the `condition_key` is tokenized.
                    length(regexall(local.terraform_string_interpolation_pattern, try(coalesce(condition_key), ""))) > 0
                    ? try(
                      # LOOK FOR `condition_key` as string interpolation in `local.type_A_tags_with_no_dependencies_value_resolver`.
                      lookup(local.type_A_tags_with_no_dependencies_value_resolver, condition_key).value,
                      # IF no interpolation replacement is found, return null.
                      null
                    )
                    # IF `condition_key` is not tokenized, return it as is.
                    : condition_key
                  )
                  condition_values = [
                    for condition_value in condition_values : (
                      # CHECK whether the `condition_value` is tokenized.
                      length(regexall(local.terraform_string_interpolation_pattern, try(coalesce(condition_value), ""))) > 0
                      ? try(
                        # LOOK FOR `condition_value` as string interpolation in `local.type_A_tags_with_no_dependencies_value_resolver`.
                        lookup(local.type_A_tags_with_no_dependencies_value_resolver, condition_value).value,
                        # IF no interpolation replacement is found, return null.
                        null
                      )
                      # IF `condition_value` is not tokenized, return it as is.
                      : condition_value
                    )
                  ]
                }
              ]
            }
            format_definition = default_value_definition.format
            format = [
              for format_argument in default_value_definition.format : (
                # CHECK whether the `format_argument` is tokenized.
                length(regexall(local.terraform_string_interpolation_pattern, try(coalesce(format_argument), ""))) > 0
                ? try(
                  # LOOK FOR `format_argument` as string interpolation in `local.type_A_tags_with_no_dependencies_value_resolver`.
                  lookup(local.type_A_tags_with_no_dependencies_value_resolver, format_argument).value,
                  # IF no interpolation replacement is found, return null.
                  null
                )
                # IF `format_argument` is not tokenized, return it as is.
                : format_argument
              )
            ]
          }
        ],
        scope = [ # BUILD `scope` with argument replacements (either scope_definition key or scope_definition values).
          for scope_key, scope_values in tag_definition.scope_definition : {
            condition_key = (
              # CHECK whether the `scope_definition` key is tokenized.
              length(regexall(local.terraform_string_interpolation_pattern, try(coalesce(scope_key), ""))) > 0
              ? try(
                # LOOK FOR `scope_definition` key as string interpolation in `local.type_A_tags_with_no_dependencies_value_resolver`.
                lookup(local.type_A_tags_with_no_dependencies_value_resolver, scope_key).value,
                # IF no interpolation replacement is found, return null.
                null
              )
              # IF `scope_definition` key is not tokenized, return it as is.
              : scope_key
            )
            condition_values = [
              for scope_value in scope_values : (
                # CHECK whether the `scope_definition` value is tokenized.
                length(regexall(local.terraform_string_interpolation_pattern, try(coalesce(scope_value), ""))) > 0
                ? try(
                  # LOOK FOR `scope_definition` value as string interpolation in `local.type_A_tags_with_no_dependencies_value_resolver`.
                  lookup(local.type_A_tags_with_no_dependencies_value_resolver, scope_value).value,
                  # IF no interpolation replacement is found, return null.
                  null
                )
                # IF `scope_definition` value is not tokenized, return it as is.
                : scope_value
              )
            ]
          }
        ]
      }
    )
  }

  type_B_tags_dependency_with_dependencies_default_value_fulfilled_conditions = {
    # [STAGE 2.1] EVALUATE all `default_value` conditions that are fulfilled in current context.
    for tag_name, tag_definition in local.type_B_tags_dependency_with_dependencies_definition :
    tag_name => {
      for default_value_definition in tag_definition.default_value : default_value_definition.index => default_value_definition
      if(
        alltrue( # Every condition in `string_equals` must be fulfilled.
          [
            for condition in try(coalesce(default_value_definition.condition.string_equals), {}) : (
              anytrue( # Condition is fulfilled if the `condition_key` MATCHES any of the `condition_values`.
                [
                  for condition_value in condition.condition_values : try(           # `regexall` function raises an error if `value` or `condition_key` is null.
                    length(regexall(condition_value, condition.condition_key)) == 1, # CHECK whether `condition_key` matches the condition_value pattern.                    
                    condition.condition_key == null && condition_value == null       # Condition is fulfilled as well if both condition_key and condition_value are null.
                  )
                ]
              )
            )
          ]
          ) && alltrue( # Every condition in `string_not_equals` must be fulfilled.
          [
            for condition in try(coalesce(default_value_definition.condition.string_not_equals), {}) : (
              !anytrue( # Condition is fulfilled if the `condition_key` DOES NOT MATCH any of the `condition_values`.
                [
                  for condition_value in condition.condition_values : try(           # `regexall` function raises an error if `value` or `condition_key` is null.
                    length(regexall(condition_value, condition.condition_key)) == 1, # CHECK whether `condition_key` matches the condition_value pattern.
                    condition.condition_key == null && condition_value == null       # Condition is fulfilled as well if both condition_key and condition_value are null.
                  )
                ]
              )
            )
          ]
        )
      )
    }
  }

  type_B_tags_dependency_with_dependencies_default_value_definition = {
    # [STAGE 2.2] TAKE only the first default_value with fulfilled condition (if any) according to the same order of precedence as they where defined in tag definition.
    for tag_name, fulfilled_default_value_definitions in local.type_B_tags_dependency_with_dependencies_default_value_fulfilled_conditions :
    tag_name => lookup(fulfilled_default_value_definitions, try(min(keys(fulfilled_default_value_definitions)...), ""), null)
  }

  type_B_tags_dependency_with_dependencies_default = tomap(
    {
      # [STAGE 2.3] BUILD default value for Type B tags.
      # If the tag definition contains a `default_value` format for current conditions, apply it to generate default value for tag.
      for tag_name, tag_default_value_definition in local.type_B_tags_dependency_with_dependencies_default_value_definition :
      tag_name => try(
        format(tag_default_value_definition.format...),
        null
      )
      if tag_default_value_definition != null
    }
  )

  type_B_tags_dependency_with_dependencies_value_resolver = tomap(
    # Merge all interpolations (for locals, input vars and mandatory tags) in a single map.
    merge(
      local.type_A_tags_with_no_dependencies_value_resolver,
      {
        # [STAGE 2.4] Resolve value from given input or default for Type B tags.
        for tag_name in keys(local.type_B_tags_dependency_with_dependencies_definition) :
        "$${var.mandatory_tags.${tag_name}}" => {
          key = tag_name
          value = try(
            # AVOID null values.
            coalesce(
              # Try to GET given value from vars.
              lookup(var.mandatory_tags, tag_name, null),
              # GET default value if not given.
              lookup(local.type_B_tags_dependency_with_dependencies_default, tag_name, null)
            ),
            # RESOLVE null if no value is given and not default is set.
            null
          )
        }
      }
    )
  )
}
