module "ec2-image-builder" {
  source                = "./modules/ec2-image-builder/"
  for_each              = var.image_builder_config

  name                  = each.value.image_builder_ami_name_tag
  vpc_id                = var.vpc_id
  subnet_id             = var.subnet_id
  aws_region            = data.aws_region.current.region
  source_cidr           = ["0.0.0.0/0"]
  create_security_group = (var.security_group_ids==null ? true : false)
  security_group_ids    = var.security_group_ids
  instance_key_pair     = null
  instance_types        = each.value.image_builder_instance_types
  source_ami_name       = data.aws_ami.source_ami[each.key].name
  ami_name              = each.value.image_builder_ami_name_tag
  ami_description       = "${data.aws_ami.source_ami[each.key].description} (${each.value.image_builder_ami_name_tag})" 
  recipe_version        = try(each.value.image_builder_image_recipe_version,"1.0.0")
  recipe_volume_size    = each.value.image_builder_ebs_root_vol_size
  managed_components    = each.value.component_names
  build_component_arn   = [for k,v in aws_imagebuilder_component.custom: v.arn if split("-",k)[0] == each.key ] #TODO: completar e.g.:  arn:aws:imagebuilder:ap-southeast-2:XXXXXXXXXXX:component/win2022build/0.0.1/1
  test_component_arn    = []
  attach_custom_policy  = true
  custom_policy_arn     = aws_iam_policy.policy.arn
  platform              = title(coalesce(data.aws_ami.source_ami[each.key].platform,"Linux"))
  schedule_expression   = try(each.value.image_builder_schedule,[])
  tags                  = merge(var.mandatory_tags, var.custom_tags)

  organization_arns     = [data.aws_organizations_organization.org.arn]

  kms_arn               = aws_kms_key.image-builder.arn
  ami_regions_kms_key   = ["us-east-2"]

  email_notifications   = each.value.email_notifications

  depends_on = [ aws_imagebuilder_component.custom, aws_kms_replica_key.kms_replica ]
}

