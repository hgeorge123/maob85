#--------------------------
# TAG INPUT VALUE PROCESSOR
#--------------------------

# This file holds the logic to set default values for those tags with a null value and a default_value format set in its tag definition.
# depends_on = [
#     "${path.module}/value_resolver.tf",
#     "${path.module}/tag_definition.tf"
# ]

locals {
  mandatory_tag_values_by_tag_name = {
    for _, tag_value_resolver in local.mandatory_tags_value_resolver :
    tag_value_resolver.key => tag_value_resolver.value
  }

  mandatory_tag_names_with_a_value = toset(
    flatten(
      [
        [
          # Tags to be included as mandatory_tags because a default value can be set if not given in `var.mandatory_tags`
          for tag_name, tag_resolved_value in local.mandatory_tag_values_by_tag_name : tag_name
          if(
            # Ignore tags not defined as mandatory in the current scope.
            lookup(local.scoped_tags_definition, tag_name, null) != null &&
            # Ignore tags with a `null` value
            tag_resolved_value != null
          )
        ],
        keys(var.mandatory_tags)
      ]
    )
  )

  mandatory_tags = {
    # Iterate mandatory_tags to set default values if not set in `var.mandatory_tags` input map.
    for tag_name in local.mandatory_tag_names_with_a_value : tag_name => try(
      coalesce(
        # TRY to get given value from input.
        lookup(var.mandatory_tags, tag_name, null),
        # GET default value if not given as input.
        lookup(local.mandatory_tag_values_by_tag_name, tag_name, null)
      ),
      null
    )
    # DISCARD tags when naming an associated resource and that tag is out of the current scope.
    # This avoids "out of scope" errors when processing tags for associated resources.
    if !(local.is_associated_resource && !try(lookup(local.tags_definition, tag_name).is_eligible_in_current_scope, false))
  }
}
