#---------------------------------------
# GLOBAL NAMING CONVENTION
#---------------------------------------
variable "entity" {}
variable "environment" {}
variable "app_name" {}
variable "function" {}
variable "sequence" {}

#---------------------------------------
# GLOBAL TAGGING CONVENTION
#---------------------------------------
variable "mandatory_tags" {}

variable "custom_tags" {}

#---------------------------------------
# PRODUCT-SPECIFIC VARIABLES
#---------------------------------------
variable "vpc_id" {}
variable "subnet_ids" {}
variable "security_group_ids" {}

variable "filename" {}

variable "runtime" {}
variable "timeout" {}
variable "memory_size" {}
variable "variables" {}
variable "create_concurrency_config" {}

variable "create_acw_event_rule" {}
variable "name_event_rule" {}
variable "description_event_rule" {}
variable "metrics_event_rule_time" {}
variable "target_id_event_target" {}

variable "triggers" {}
variable "create_lambda_function_url" {}
variable "lambda_function_url_cors" {}
