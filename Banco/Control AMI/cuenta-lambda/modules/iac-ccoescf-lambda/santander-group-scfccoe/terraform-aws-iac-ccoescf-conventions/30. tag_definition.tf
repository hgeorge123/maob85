#---------------
# TAG DEFINITION
#---------------

# This file holds the logic to take only the tags definition subset for current scope.
# depends_on = [
#     "${path.module}/assets/tag_definition_loader.tf",        
#     "${path.module}/value_resolver*.tf"
# ]

locals {
  # DEFINE a variable with every tag definition after being processed (validated, tokenized values replaced, etc.)
  tags_definition = tomap(
    # EVALUATE whether a tag is eligible in current scope.
    {
      for tag_name, tag_definition in merge(
        # USE following locals, as scope tokenized values are replaced there.
        local.type_A_tags_with_no_dependencies_definition,
        local.type_B_tags_dependency_with_dependencies_definition,
        local.type_C_tags_not_dependency_with_dependencies_definition
      ) :
      tag_name => merge(
        tag_definition,
        {
          # ADD a property to determine whether this tag is eligible (can be applied) in current scope.
          is_eligible_in_current_scope = contains(tag_definition.scope.*.condition_key, local.default_scope) || alltrue(
            # Every scope definition must be fulfilled.
            [
              for scope_condition in tag_definition.scope : anytrue(
                # Scope definition is fulfilled if the `scope_key` MATCHES any of the `scope_expected_values`.
                [
                  for scope_condition_value in scope_condition.condition_values : try(           # `regexall` function raises an error if `scope_value` or `scope_key` is null.
                    length(regexall(scope_condition_value, scope_condition.condition_key)) == 1, # CHECK whether `scope_key` matches the `scope_value` pattern.                    
                    scope_condition.condition_key == null && scope_condition_value == null       # Scope definition is fulfilled as well if both `scope_key` and `scope_value` are null.
                  )
                ]
              )
            ]
          )
        }
      )
    }
  )

  tag_default_values = tomap(
    {
      for tag_name, tag_definition in local.tags_definition : tag_name => tag_definition.default_value
      if try(tag_definition.default_value, null) != null
    }
  )

  scoped_tags_definition = {
    for tag_name, tag_definition in local.tags_definition : tag_name => tag_definition
    # Consider only tags in global scope or if the current scope matches one of the defined in tag_definition.
    if tag_definition.is_eligible_in_current_scope
  }
}
