variable "filename" {
  description = "(Required) The name of the file, it should be saved in Lambda_functions folder in .zip"
  type        = string
}

variable "filename_hash" {
  description = "(Required) The hash of the file, it should be saved in Lambda_functions folder in .zip"
  type        = string
}

variable "create_lambda_function_url" {
  description = "(Optional) Create Lambda Function url"
  type        = bool
  default     = false
}

variable "lambda_function_url_cors" {
  description = "(Optional) A dimension is a name/value pair that helps identify a metric. The source specifies where the dimension can be retrieved."
  type = object({
    allow_credentials = bool
    # (Optional) Whether to allow cookies or other credentials in requests to the function URL. The default is false.
    allow_origins = list(string)
    # (Optional) The origins that can access the function URL. You can list any number of specific origins (or the wildcard character ("*")), separated by a comma. For example: ["https://www.example.com", "http://localhost:60905"].
    allow_methods = list(string)
    # (Optional) The HTTP methods that are allowed when calling the function URL. For example: ["GET", "POST", "DELETE"], or the wildcard character (["*"]).
    allow_headers = list(string)
    # (Optional) The HTTP headers that origins can include in requests to the function URL. For example: ["date", "keep-alive", "x-custom-header"].
    expose_headers = list(string)
    # (Optional) The HTTP headers in your function response that you want to expose to origins that call the function URL.
    max_age = number
    # (Optional) The maximum amount of time, in seconds, that web browsers can cache results of a preflight request. By default, this is set to 0, which means that the browser doesn't cache results. The maximum value is 86400.
  })
  default = null

}

variable "create_concurrency_config" {
  description = "(Optional) Create concurrency config"
  type        = bool
  default     = false
}

variable "reserved_concurrent_executions" {
  description = "(Optional) The amount of reserved concurrent executions for this lambda function. A value of 0 disables lambda from being triggered and -1 removes any concurrency, for default 1 "
  type        = number
  default     = 1
}

variable "name_event_rule" {
  description = "(Optional, **Deprecated**, Forces new resource) Name the lambda -cwr"
  type        = string
  default     = ""
}

variable "description_event_rule" {
  description = "(Optional, **Deprecated**) The description of the rule"
  type        = string
  default     = ""
}

variable "handler" {
  description = "(Optional) The entry point of the lambda"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "metrics_event_rule_time" {
  description = "(Required, **Deprecated**, if event_pattern isn't specified) The scheduling expression. For example, cron(0 20 * * ? *) or rate(5 minutes)"
  type        = string
  default     = "rate(5 minutes)"
}

variable "create_acw_event_rule" {
  description = "(Optional, **Deprecated**, Forces new resource) Create Cloudwatch event rule"
  type        = bool
  default     = true
}

variable "target_id_event_target" {
  description = "(Optional, **Deprecated**, Forces new resource) Target id of event target"
  type        = string
  default     = "lambda"
}

variable "triggers" {
  type = list(
    object({
      name = string
      # (Optional) The name of the trigger. If omitted, Terraform will assign a random, unique name
      description         = string # (Optional) The description of the trigger.
      schedule_expression = string
      # (Required) The scheduling expression. For example, cron(0 20 * * ? *) or rate(5 minutes). See: <https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html>.
      target_id = string
      # (Optional) The unique target assignment ID. If missing, will generate a random, unique id.
      input_transformer = object({
        # (Optional) Parameters used when you are providing a custom input to a target based on certain event data.
        input_paths = map(string)
        # (Optional) Key value pairs specified in the form of JSONPath (for example, time = $.time)
        input_template = string # (Required) Template to customize data sent to the target.
      })
    })
  )
  description = <<EOT
(Optional, Forces new resource) Amazon EventBridge events definition to trigger the Lambda Function.
See: <https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-run-lambda-schedule.html>
See also: <https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target>
  EOT
  default     = []
}

variable "lambda_role" {
  description = "(Required) The name of the lambda's role"
  type        = string
}

variable "architectures" {
  description = "(Optional) Instruction set architecture for your Lambda function. Valid values are [x86_64] and [arm64]. Default is [x86_64]. Removing this attribute, function's architecture stay the same."
  type        = list(string)
  default     = ["x86_64"]
}
variable "ephemeral_storage" {
  description = "(Optional)Lambda Function Ephemeral Storage(/tmp) allows you to configure the storage upto 10 GB. The default value set to 512 MB."
  type        = string
  default     = "512"
}

variable "runtime" {
  description = "(Optional) Identifier of the function's runtime. See <https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html> for valid values."
  type        = string
  default     = "python3.9"
}

variable "timeout" {
  description = "(Optional) The amount of time your Lambda Function has to run in seconds. Defaults to 3."
  type        = number
  default     = 3
}

variable "kms_key_arn" {
  description = "(Optional) Amazon Resource Name (ARN) of the AWS Key Management Service (KMS) key that is used to encrypt environment variables. "
  type        = string
  default     = null
}

variable "variables" {
  description = "(Optional) A map that defines environment variables for the Lambda function."
  type        = map(any)
  default     = {}
}

variable "memory_size" {
  description = "(Optional) Amount of memory needed for the lambda function."
  type        = number
  default     = 256
}

variable "subnet_ids" {
  description = "(Required, Forces new resource) Subnets where the lambda function will be deployed."
  type        = list(string)
}

variable "vpc_id" {
  description = "(Required, Forces new resource) VPC where the lambda function will be deployed."
  type        = string
}

variable "security_group_ids" {
  description = "(Required) Security groups that will be applied to the lambda function."
  type        = list(string)
}

variable "efs_mount_path" {
  description = "(Optional) The path where the function can access the file system, starting with /mnt/."
  type        = string
  default     = null
}

variable "access_point_id" {
  description = "(Optional) The Amazon EFS Access Point ID that provides access to the file system."
  type        = string
  default     = null
}

variable "layers_arn" {
  type        = list(string)
  description = "(Optional) Collection of Layer ARNs with lambda requirements/dependencies."
  default     = null
}

// Tagging

variable "mandatory_tags" {
  description = "(Required) Map of strings to be assigned as resource tags, compliant with Santander Group Tagging Standard. See: <https://confluence.alm.europe.cloudcenter.corp/pages/viewpage.action?spaceKey=arqdevops&title=Tags>"
  type        = map(string)
}

variable "custom_tags" {
  description = "(Optional) Additional tags. If some key matches one of the mandatory tags, its value shall be ignored."
  type        = map(string)
  default     = {}
}

// Naming

variable "entity" {
  description = "(Required, Forces new resource) Santander entity code. Used for Naming. (3 characters) "
  type        = string

  validation {
    condition     = length(regexall("^[[:alnum:]]{3}$", var.entity)) == 1
    error_message = "The `entity` value must be a valid Santander Group entity code, with just 3 characters."
  }
}

variable "environment" {
  description = "(Required, Forces new resource) The abbreviation for the target environment."
  type        = string

  validation {
    condition     = length(regexall("^[[:alnum:]]{2}$", var.environment)) == 1
    error_message = "The `environment` value must be a valid environment code, with just 2 characters."
  }
}

variable "app_name" {
  description = "(Required, Forces new resource) App acronym of the resource. Used for Naming. (6 characters) "
  type        = string

  validation {
    condition     = length(regexall("^[[:alnum:]]{6}$", var.app_name)) == 1
    error_message = "The `app_name` value must be a valid Santander Group application name, with just 6 characters."
  }
}

variable "function" {
  description = "(Optional, Forces new resource) App function of the resource. Used for Naming. (4 characters) "
  type        = string
  default     = "gene"

  validation {
    condition     = length(regexall("^[[:alnum:]]{4}$", var.function)) == 1
    error_message = "When `function` is given, its value must be a valid function code, with just 4 characters."
  }
}

variable "sequence" {
  description = "(Required, Forces new resource) Sequence number of the resource. Used for Naming. (1 to 3 digits)"
  type        = number

  validation {
    condition     = 1 <= var.sequence && var.sequence <= 999
    error_message = "The `sequence` value must be a valid positive number, between 1 and 999."
  }
}
