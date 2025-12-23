locals{
  components = merge([
    for ibc_k, ibc_v in var.image_builder_config: {
      for c_k, c_v in ibc_v.custom_components : 
            "${ibc_k}-${c_v.name}" => c_v
      }            
    ]...
  )  
}

resource "aws_imagebuilder_component" "custom" {
  for_each = local.components
  
  name     = each.value.name
  platform = title(coalesce(data.aws_ami.source_ami[split("-", each.key)[0]].platform,"Linux"))
  version  = var.image_builder_config[split("-", each.key)[0]].image_builder_image_recipe_version
  data     = file("${path.module}/files/${each.value.filename}")
  tags     = merge(var.mandatory_tags, var.custom_tags)

  lifecycle {
    create_before_destroy = true
  }

}