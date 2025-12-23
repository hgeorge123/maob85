#COMMON
variable "vpc_id" {
  type = string
}

variable "mandatory_tags" {
  type = map(string)
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

variable "lambda_name" {
  type = string
}

variable "lambda_arn" {
  type = string
}

variable "organization" {
  type = list(string)
}


variable "dynamodb_items" {
  description = "DynamoDB Table Items"
  type = list(object({
    allow_type   = string
    allow_value     = string
    account    = any
  }))
}

variable "subnet_ids" {
  type = list(string)
}