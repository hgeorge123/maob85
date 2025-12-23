terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

module "iac-ccoescf-control-ami" {
  source = "./modules/iac-ccoescf-control-ami/"
  vpc_id = var.vpc_id
  mandatory_tags = var.mandatory_tags
  sg_ingress_rules = var.sg_ingress_rules
  sg_egress_rules = var.sg_egress_rules
  lambda_name = module.iac-ccoescf-lambda.this_lambda_function_name
  lambda_arn = module.iac-ccoescf-lambda.this_lambda_function_arn
  organization = var.organization
  dynamodb_items = var.dynamodb_items
  subnet_ids = var.subnet_ids
}

module "iac-ccoescf-lambda" {
  source = "./modules/iac-ccoescf-lambda/"

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
  lambda_role = module.iac-ccoescf-control-ami.ami_role_for_lambda 

  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids
  security_group_ids = [module.iac-ccoescf-control-ami.security_group_id_for_lambda]

  filename      = var.filename
  filename_hash = filebase64sha256(var.filename)

  runtime                   = var.runtime
  timeout                   = var.timeout
  memory_size               = var.memory_size
  variables                 = var.variables
  create_concurrency_config = var.create_concurrency_config
  layers_arn =  [""]
  
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