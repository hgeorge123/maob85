#---------------------------------------
# GLOBAL NAMING CONVENTION
#---------------------------------------
entity      = "scf"
environment = "d1"
app_name    = "iacprd"
function    = "gene"
sequence    = "001"

#---------------------------------------
# GLOBAL TAGGING CONVENTION
#---------------------------------------
mandatory_tags = {
  Cost_Center    = "TEST"
  Channel        = "TEST"
  CIA            = "AAA"
  Product        = "TEST"
  Description    = "TEST"
  Tracking_Code  = "TEST"
  APM_functional = "ORBIS_code_001"
  shared_costs   = "no"
}

custom_tags = { "custom_tag_key" = "custom_tag_value" }

#---------------------------------------
# PRODUCT-SPECIFIC VARIABLES
#---------------------------------------
vpc_id = "vpc-02505ec8112b29a4e"
subnet_ids = [
  "subnet-0a21050ed62cf50e7",
  "subnet-007ffdf287a6694d9"
]
security_group_ids = ["sg-022ecfbc536b6d3ae"]

filename = "lambda_function.zip"

runtime                   = "python3.8"
timeout                   = 5
memory_size               = 256
variables                 = {}
create_concurrency_config = false
# access_point_id           = "fsap-xxxxxxxxxxxxxxx"
# efs_mount_path            = "/mnt/efs"

// acw event rule
create_acw_event_rule   = true
name_event_rule         = "Name_event"
description_event_rule  = "Description"
metrics_event_rule_time = "rate(5 minutes)"
target_id_event_target  = "test_target_id"

triggers = [
  {
    name                = "my_custom_trigger"
    description         = "trigger description"
    schedule_expression = "rate(1 minute)"
    target_id           = "lambda_test"
    input_transformer = {
      input_paths = {
        time = "$.time"
      }
      input_template = <<EOT
{
  "first_name": "John",
  "last_name": "Smith at <time>"
}
EOT
    }
  }
]

create_lambda_function_url = true

lambda_function_url_cors = {
  allow_credentials = true
  allow_origins     = ["https://www.example.com"]
  allow_methods     = ["POST"]
  allow_headers     = ["date", "keep-alive", "x-custom-header"]
  expose_headers    = null
  max_age           = 2
}

#lambda_function_url_cors = null