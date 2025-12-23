data "aws_subnet" "subnet" {
  count  = length(var.subnet_ids)
  id     = var.subnet_ids[count.index]
  vpc_id = var.vpc_id
}

data "aws_security_group" "sg" {
  count = length(var.security_group_ids)
  id    = var.security_group_ids[count.index]
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_kms_key" "kms_key" {
  depends_on = [local.kms_key_arn]
  key_id     = local.kms_key_arn
}

data "aws_efs_access_point" "test" {
  count           = var.access_point_id == null ? 0 : 1
  access_point_id = var.access_point_id
}

module "conventions" {
  #source = "github.com/santander-group-scfccoe/terraform-aws-iac-ccoescf-conventions"
  source = "./santander-group-scfccoe/terraform-aws-iac-ccoescf-conventions"


  # AWS TAGGING
  mandatory_tags = merge(
    var.mandatory_tags,
    {
      # AWS TAGGING - ALM
      artifact_version = jsondecode(file("${path.module}/version.json")).version
      cloud_version    = var.runtime
      artifact_name    = "lambda"
    }
  )

  custom_tags = var.custom_tags

  # AWS NAMING
  entity           = var.entity
  environment      = var.environment
  app_name         = var.app_name
  function         = var.function
  sequence         = var.sequence
  artifact_acronym = "lam"
}

locals {
  naming   = module.conventions.product_name
  region   = module.conventions.geo_region
  filename = join("", [replace(var.filename, "/\\.[zZ][iI][pP]$/", ""), ".zip"]) # Support filename without extension.
}

resource "aws_lambda_function" "this" {
  depends_on       = [data.aws_kms_key.kms_key, data.aws_subnet.subnet, data.aws_security_group.sg]
  filename         = local.filename
  source_code_hash = var.filename_hash
  publish          = true
  function_name    = local.naming
  description      = lookup(var.mandatory_tags, "description", "Lambda function ${local.naming}")
  role             = var.lambda_role
  handler          = var.handler
  runtime          = var.runtime
  timeout          = var.timeout
  kms_key_arn      = local.kms_key_arn
  memory_size      = var.memory_size
  layers           = var.layers_arn
  architectures    = var.architectures

  ephemeral_storage {
    size = var.ephemeral_storage
  }
  vpc_config {
    subnet_ids         = data.aws_subnet.subnet[*].id
    security_group_ids = data.aws_security_group.sg[*].id
  }
  dynamic "environment" {
    for_each = length(keys(var.variables)) == 0 ? [] : [true]
    content {
      variables = var.variables
    }
  }
  dynamic "file_system_config" {
    for_each = var.efs_mount_path == null ? [] : [true]
    content {
      arn              = data.aws_efs_access_point.test[0].arn
      local_mount_path = var.efs_mount_path
    }
  }

  tags = module.conventions.tags

  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash
    ]
  }
}

resource "aws_lambda_function_url" "this" {
  count         = var.create_lambda_function_url ? 1 : 0
  function_name = aws_lambda_function.this.function_name
  #qualifier          = "$LATEST" #aws_lambda_function.this.version
  authorization_type = "AWS_IAM"
  dynamic "cors" {
    for_each = toset(var.lambda_function_url_cors != null ? [true] : [])
    content {
      allow_credentials = try(var.lambda_function_url_cors.allow_credentials, false)
      allow_origins = try(var.lambda_function_url_cors.allow_origins != [
        "*"
      ] ? var.lambda_function_url_cors.allow_origins : null, [""])
      allow_methods  = try(var.lambda_function_url_cors.allow_methods, null)
      allow_headers  = try(var.lambda_function_url_cors.allow_headers, null)
      expose_headers = try(var.lambda_function_url_cors.expose_headers, null)
      max_age        = try(var.lambda_function_url_cors.max_age, 0)
    }
  }
}

locals {
  # deprecated_triggers will be an empty list if var.triggers is filled
  deprecated_triggers = var.triggers == [] && var.create_acw_event_rule ? [{
    name                = var.name_event_rule
    description         = var.description_event_rule
    schedule_expression = var.metrics_event_rule_time
    target_id           = var.target_id_event_target // "lambda"
    input_transformer   = null
  }] : []

  triggers = concat(var.triggers, local.deprecated_triggers)

  triggers_by_name = tomap({
    for index, trigger in local.triggers : coalesce(trigger.name, format("%s-cwr%02d", local.naming, index)) => merge(
      trigger,
      {
        name        = coalesce(trigger.name, format("%s-cwr%02d", local.naming, index))
        description = coalesce(var.description_event_rule, format("Event rule %02d for %s", index, local.naming))
      }
    )
  })
}

resource "aws_cloudwatch_event_rule" "trigger_event_rule" {
  for_each = local.triggers_by_name

  name                = each.key
  description         = each.value.description
  schedule_expression = each.value.schedule_expression

  tags = module.conventions.tags
}

resource "aws_cloudwatch_event_target" "trigger_event_target" {
  for_each = aws_cloudwatch_event_rule.trigger_event_rule

  rule      = each.key # aws_cloudwatch_event_rule.trigger_event_target[*].name
  target_id = try(local.triggers_by_name[each.key].target_id, null)
  arn       = aws_lambda_function.this.arn

  dynamic "input_transformer" {
    for_each = toset([
      for trigger_name, trigger in local.triggers_by_name : trigger.input_transformer
      if trigger_name == each.key && try(trigger.input_transformer.input_template, null) != null
    ])

    content {
      input_paths    = input_transformer.value.input_paths
      input_template = input_transformer.value.input_template
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_function" {
  for_each = aws_cloudwatch_event_rule.trigger_event_rule

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = each.value.arn
}

resource "aws_lambda_provisioned_concurrency_config" "config" {
  count                             = var.create_concurrency_config ? 1 : 0
  function_name                     = aws_lambda_function.this.function_name
  provisioned_concurrent_executions = var.reserved_concurrent_executions
  qualifier                         = aws_lambda_function.this.version
}
