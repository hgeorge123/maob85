#--------------
# TAG VALIDATOR
#--------------

# This file holds the logic to:
#   * Ensure that all required tags are set.
#   * No other tags (out from tag_definition) are set as mandatory_tags.
#   * No mandatory tags are passed as custom tags (trying to avoid validation process).
#   * No tags are set out of its scope (a tag scoped to type X resources cannot be set for type Y resources).
#   * Validate tag values.
# File dependencies:
# depends_on = [
#     "${path.module}/tag_definition.tf",
#     "${path.module}/tag_input_value_processor.tf"
# ]

locals {
  required_tags = [
    for tag_key, tag_definition in local.scoped_tags_definition : tag_key
    if tag_definition.is_required
  ]

  required_tags_error_messages = [
    # Check that a value is given (or is resolved by default) for required tags.
    for required_tag in local.required_tags : {
      tag           = required_tag
      value         = null
      error_message = <<EOT
No value has been given for Required Mandatory tag and no default value could be resolved.
If a `default_value` format has been set in tag definition, maybe some of its dependencies are `null`.
      EOT
      tag_definition = {
        default_value = lookup(local.tag_default_values, required_tag, null)
      }
    }
    if lookup(local.mandatory_tags, required_tag, null) == null
  ]

  mandatory_tags_validation_error_messages = [
    for mandatory_tag_key, mandatory_tag_value in local.mandatory_tags : {
      tag           = mandatory_tag_key
      value         = mandatory_tag_value
      error_message = local.scoped_tags_definition[mandatory_tag_key].validation.error_message
      tag_definition = {
        validation = {
          pattern = local.scoped_tags_definition[mandatory_tag_key].validation.pattern
        }
      }
    }
    if(
      # Do not check when validation pattern is null.
      try(
        lookup(local.scoped_tags_definition, mandatory_tag_key).validation.pattern,
        null
      ) != null
      # Add validation error if tag value does not match validation pattern.
      && try(       # CATCH error raised due to null or empty validation.pattern and FORCE condition.
        length(     # CHECK whether regex matches only once.
          regexall( # FIND all regex matches for tag validation pattern in tag value.
            lookup(local.scoped_tags_definition, mandatory_tag_key).validation.pattern,
            mandatory_tag_value
          )
        ) != 1,
        true
      )
    )
  ]

  non_mandatory_tags_validation_error_messages = [
    # Find non mandatory tags passed as mandatory. Detect tags set out of its scope.
    for mandatory_tag_key, mandatory_tag_value in local.mandatory_tags : {
      tag   = mandatory_tag_key
      value = mandatory_tag_value
      error_message = (
        lookup(local.tags_definition, mandatory_tag_key, null) == null # IF tag definition has not been loaded, print "DEFINITION NOT FOUND" message.
        ? <<EOT
Tag in $${var.mandatory_tags} DEFINITION NOT FOUND.
If you need to add extra tags, pass them as $${var.custom_tags}.
        EOT
        : <<EOT
Tag in $${var.mandatory_tags} has been set out of its scope.
This tag cannot be set for the current scope, neither as a $${var.custom_tags} item.
        EOT
      )
      tag_definition = (
        lookup(local.tags_definition, mandatory_tag_key, null) == null # IF tag definition has not been loaded, let it empty.
        ? null
        : {
          scope = local.tags_definition[mandatory_tag_key].scope_definition
        }
      )
    }
    if lookup(local.scoped_tags_definition, mandatory_tag_key, null) == null
  ]

  custom_tags_validation_error_messages = [
    # Find mandatory tags passed as custom to avoid validation.
    for tag_name, tag_value in var.custom_tags : {
      tag           = tag_name
      value         = tag_value
      error_message = <<EOT
Tag in $${var.custom_tags} FOUND in mandatory tags definition.
Please move it to $${var.mandatory_tags} to perform validation.
EOT
      tag_definition = [
        for tag_key, tag_definition in local.tags_definition : {
          name        = tag_key
          is_required = tag_definition.is_required
          scope       = tag_definition.scope_definition
          validation  = tag_definition.validation
        }
        if tag_definition.tag_lowercase == lower(trimspace(tag_name))
      ][0]
    }
    if anytrue([
      for tag_key, tag_definition in local.tags_definition : tag_definition.tag_lowercase == lower(trimspace(tag_name))
    ])
  ]

  errors = flatten(
    [
      local.required_tags_error_messages,
      local.mandatory_tags_validation_error_messages,
      local.non_mandatory_tags_validation_error_messages,
      local.custom_tags_validation_error_messages
    ]
  )

  error_messages = jsonencode({
    description = "Tags with a tailing asterisk (*) are required."

    errors = local.errors

    loaded_mandatory_tags_definition = [
      # Tag definitions loaded from yaml input file.
      for tag_key, tag_definition in local.tags_definition : format("%s%s", tag_key, tag_definition.is_required ? " (*)" : "")
    ]

    current_scope_supported_mandatory_tags = [
      # Tag definitions matching the current scope.
      for tag_key, tag_definition in local.scoped_tags_definition : format("%s%s", tag_key, tag_definition.is_required ? " (*)" : "")
    ]

    evaluated_mandatory_tags = [
      # Tags matching the current scope which value has been set and evaluated/validated.
      for tag_key in local.mandatory_tag_names_with_a_value : format("%s%s", tag_key, lookup(local.scoped_tags_definition, tag_key, { is_required = false }).is_required ? " (*)" : "")
    ]

    mandatory_tag_resolved_values = local.mandatory_tags # Mandatory tags result.
  })
}

resource "null_resource" "errors" {
  # This throws an `Incorrect value type` error when some error message is present.
  # CLI output format:
  # │     │ local.errors is tuple with <number_of_detected_errors> elements
  # │
  # │ Invalid expression value: a number is required.
  count = length(local.errors) == 0 ? 0 : coalesce(local.error_messages, 1)
}
