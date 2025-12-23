#----------------------
# TAG DEFINITION LOADER
#----------------------

# This file holds the logic to import tags definition from yaml input file.
# depends_on = [
#     "${path.module}/assets/tags_definition.yaml"
# ]

locals {
  terraform_string_interpolation_pattern                = "^\\$${.+}$"                        # matches interpolation-style string values like ${var.mandatory_tags.CIA} or ${local.function}
  terraform_string_mandatory_tags_interpolation_pattern = "^\\$${var\\.mandatory_tags\\..+}$" # matches interpolation-style string values like ${var.mandatory_tags.CIA}
  default_scope                                         = "global"

  loaded_tags_definition = yamldecode(file("${path.module}/assets/tags_definition.yaml"))

  tags_definition_validated_input = tomap(
    # Tag definitions loaded from tag definition yaml file are processed to avoid runtime/execution issues with undefined or wrong values.
    {
      for tag_key, tag_definition in local.loaded_tags_definition : tag_key => {
        default_value_definition = toset(
          # CHECK whether a default_value definition is set in tag_definition
          try(coalescelist(tag_definition.default_value), null) != null
          ? [
            for default_value_definition_index, default_value_definition in try(coalescelist(tag_definition.default_value), [{ format = [] }]) :
            {
              index = default_value_definition_index # HELPS to keep condition fulfillment precedence.
              condition = try(
                # FORCE empty condition to avoid terraform `cannot convert object to map of any single type` error.
                default_value_definition.condition,
                {}
              )
              # IF a default_value definition has been provided, at least the `format` argument must have a value.
              format = default_value_definition.format
            }
          ]
          : []
        )
        is_required   = try(tag_definition.is_required, true)
        tag_lowercase = lower(tag_key)
        validation = {
          error_message = try(tag_definition.validation.error_message, null)
          pattern       = try(tag_definition.validation.pattern, null)
        }
        scope_definition = {
          for scope_key, scope_values in try(tag_definition.scope, { (local.default_scope) = [] }) : scope_key => toset(coalesce(scope_values, []))
        }
        dependencies = toset(
          # RETURN tag values and tag definition values that depend on other tags or input values.
          [
            for value in( # ITERATE values in `scope` and/or `default_value` settings.
              flatten(
                [
                  [
                    for default_value_definition in try(coalesce(tag_definition.default_value), []) : # ITERATE each `default_value` definition.
                    [
                      default_value_definition.format, # RETURN `default_value` format arguments.
                      [
                        for _, condition_block in try(coalesce(default_value_definition.condition), {}) : # ITERATE condition blocks (string_equals, string_not_equals, etc.).
                        [
                          keys(condition_block),  # RETURN condition keys
                          values(condition_block) # RETURN condition values
                        ]
                        if condition_block != null
                      ]
                    ]
                  ],
                  [
                    for scope_key, scope_values in try(tag_definition.scope, { (local.default_scope) = [] }) : [ # ITERATE `scope` key-value pairs.
                      scope_key,                                                                                 # RETURN `scope` key.
                      coalesce(scope_values, [])                                                                 # RETURN `scope` values that the `scope` key should match to consider this tag as eligible in the current context.
                    ]
                  ]
                ]
              )
            ) : value
            if try( # RETURN only values that match the a terraform interpolation pattern (${*}).
              length(regexall(local.terraform_string_interpolation_pattern, value)) > 0,
              false
            )
          ]
        )
      }
    }
  )

  # TAG DEPENDENCIES:
  # Other tags use to be referenced in tag_definition `scope` and `default_value` formatting.
  #   Examples:
  #     ```yaml
  #     scope:
  #       ${var.mandatory_tags.backup_needed}:    
  #         - true
  #     ```
  #     ```yaml
  #     default_value:
  #       - condition:
  #           string_equals:
  #             ${var.mandatory_tags.CIA}:
  #               - ^AA[ABC]$
  #           string_not_equals:
  #             ${var.app_name}:
  #               - ${var.mandatory_tags.Tracking_Code}
  #             ${var.mandatory_tags.Channel}:
  #               - null
  #         format:
  #           - "%s-%s"
  #           - CRIT
  #           - ${var.mandatory_tags.APM_functional}
  #     ```
  tags_definition_input = {
    # Evaluate whether a tag default value depends on other tags or whether a tag has dependencies on other tags (like tag scopes).
    # This is necessary to determine the order for resolving tag default values.
    for tag_name, tag_definition in local.tags_definition_validated_input : tag_name => merge(
      tag_definition,
      {
        is_dependency = anytrue(
          [
            # Determine whether other tags contain this tag as default_value argument or scope key.
            for _, dependency_tag_definition in local.tags_definition_validated_input : contains(dependency_tag_definition.dependencies, "$${var.mandatory_tags.${tag_name}}")
          ]
        )
        # Determine whether this tag definition has dependencies on other tags or input values.
        has_dependencies = length(tag_definition.dependencies) > 0
        # Determine whether this tag definition has dependencies on other tags,
        # by checking if any default_value argument or any scope key in this tag matches the `mandatory_tags` interpolation regex.
        has_tag_dependencies = length(
          [
            for dependency in tag_definition.dependencies : dependency
            if length(regexall(local.terraform_string_mandatory_tags_interpolation_pattern, dependency)) > 0
          ]
        ) > 0
      }
    )
  }

  tags_definition_input_with_no_dependencies = {
    # Tag dependency type A: A, A <- C, A <- B <- C
    # First collection of tags to resolve a value (from given as input or default).
    # Every tag in this collection has a value that can be resolved directly, without dependencies on another tag value.
    # Tags in this collection are resolved in a first stage because other tag values could depend on them.    
    for tag_name, tag_definition in local.tags_definition_input : tag_name => tag_definition
    if !tag_definition.has_tag_dependencies
  }

  tags_definition_input_dependency_with_dependencies = {
    # Tag dependency type B: A <- B <- C
    # Second collection of tags to resolve a value (from given as input or default).
    # Every tag in this collection depends on another tag value and other tags have a dependency on it.
    # Tags in this collection are resolved in a second stage, because their values depend on Type A tags,
    #   at the same time as Type C tags depend on their value.
    for tag_name, tag_definition in local.tags_definition_input : tag_name => tag_definition
    if tag_definition.is_dependency && tag_definition.has_tag_dependencies
  }

  tags_definition_input_not_dependency_with_dependencies = {
    # Tag dependency type C: A <- C, A <- B <- C
    # Last collection of tags to resolve a value (from given as input or default).
    # Every tag in this collection depends on another tag value, but there are NOT tags that have a dependency on it.
    # Tags in this collection are resolved in the last stage, because their values depend on Type A or Type B tags.
    for tag_name, tag_definition in local.tags_definition_input : tag_name => tag_definition
    if !tag_definition.is_dependency && tag_definition.has_tag_dependencies
  }
}
