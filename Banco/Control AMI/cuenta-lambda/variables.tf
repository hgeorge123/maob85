#COMMON
variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "mandatory_tags" {
  type = map(string)
}

#LAMBDA
variable "entity" {
  type = string
}

variable "environment" {
  type = string
}

variable "app_name" {
  type = string
}

variable "function" {
  type = string
}

variable "sequence" {
  type = string
}

variable "custom_tags" {
  type = map(string)
}

#variable "security_group_ids" {
#  type = list(string)
#}

variable "filename" {
  type = string
}

variable "runtime" {
  type = string
}

variable "timeout" {
  type = number
}

variable "memory_size" {
  type = number
}

variable "variables" {
  type = map(string)
}

variable "create_concurrency_config" {
  type = bool
}

variable "create_acw_event_rule" {
  type = bool
}

variable "name_event_rule" {
  type = string
}

variable "description_event_rule" {
  type = string
}

variable "metrics_event_rule_time" {
  type = string
}

variable "target_id_event_target" {
  type = string
}

variable "triggers" {
  type = list(any)
}

variable "create_lambda_function_url" {
  type = bool
}

variable "lambda_function_url_cors" {
  type = object({
    allow_credentials = bool
    allow_origins     = list(string)
    allow_methods     = list(string)
    allow_headers     = list(string)
    expose_headers    = list(string) # Cambia a 'list(string)' o 'any' si 'null' es un valor esperado
    max_age           = number
  })
}

variable "sg_ingress_rules" {
  description = "inbound rules for sg"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default =[ 
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ]
}

variable "sg_egress_rules" {
  description = "egress rules for sg"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default =[ 
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    ]
}

# CONTROL LAMBDA
variable "organization" {
  type = list(string)
}

variable "dynamodb_items" {
  description = "DynamoDB Table Items"
  type = list(object({
    allow_type   = string
    allow_value     = string
    account    = optional(string,"*")
  }))
}