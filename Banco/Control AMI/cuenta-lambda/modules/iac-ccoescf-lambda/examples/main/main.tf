module "iac-ccoescf-lambda" {
  source = "../../"

  #---------------------------------------
  # GLOBAL NAMING CONVENTION
  #---------------------------------------
  entity      = var.entity
  environment = var.environment
  app_name    = var.app_name
  function    = var.function
  sequence    = var.sequence

  #---------------------------------------
  # GLOBAL TAGGING CONVENTION
  #---------------------------------------
  mandatory_tags = var.mandatory_tags

  custom_tags = var.custom_tags

  #---------------------------------------
  # PRODUCT-SPECIFIC VARIABLES
  #---------------------------------------
  lambda_role = aws_iam_role.lambda_iam_role.arn

  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids

  filename      = var.filename
  filename_hash = filebase64sha256(var.filename)

  runtime                   = var.runtime
  timeout                   = var.timeout
  memory_size               = var.memory_size
  variables                 = var.variables
  create_concurrency_config = var.create_concurrency_config
  # access_point_id           = var.access_point_id
  # efs_mount_path            = var.efs_mount_path

  // acw event rule
  create_acw_event_rule   = var.create_acw_event_rule
  name_event_rule         = var.name_event_rule
  description_event_rule  = var.description_event_rule
  metrics_event_rule_time = var.metrics_event_rule_time
  target_id_event_target  = var.target_id_event_target

  triggers = var.triggers

  create_lambda_function_url = var.create_lambda_function_url
  lambda_function_url_cors   = var.lambda_function_url_cors
}
