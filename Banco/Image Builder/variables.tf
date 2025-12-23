#####################################################################################################
#GLOBAL NAMING POLICIES

variable "cost_center" {
  type        = string
  description = "Cost center Tag"
  default     = "" // Defined in IT Portal projects
}


variable "product" {
  type        = string
  description = "Application / workload name. This info is coming from DU.  *** Note: Only when tag shared_cost = Yes or the account is 'brownfield', Product can be empty"
  default     = "" // Defined in IT Portal projects
}

variable "cia" {
  type    = string
  default = "" // Capital letters. Example: "AAA", "ABB"
}

variable "channel" {
  type        = string
  description = "Indicates the distribution channel to which the module's resources belong to"
  default     = "Intranet"
}

variable "tracking_code" {
  type        = string
  description = "Allows the module to be matched against internal inventory systems such as Atlas"
  default     = "" // Defined in IT Portal projects
}

variable "workload_tag" {
  description = "Workload Tag"
  default     = "" // Defined in IT Portal projects
}

variable "entity" {
  type    = string
  default = "" // Defined in IT Portal projects
}

variable "environment" {
  type    = string
  default = ""
}

variable "app_name" {
  type    = string
  default = "" //workload tag (6 digits) in lower case
}

variable "shared_costs" {
  type        = string
  description = "This tag helps identify cost which cannot be allocated to a unique cost center.  *** Note: When tag Cost Center is not empty, shared cost must be No.  Accepted values: Yes / No"
  default     = "" // Defined in IT Portal projects
}

variable "apm_functional" {
  type    = string
  default = "NOT_IDENTIFIED" // Defined in IT Portal projects
}

variable "apm_technical" {
  type    = string
  default = "NOT_IDENTIFIED" // Defined in IT Portal projects
}

variable "business_service" {
  type    = string
  default = "NOT_IDENTIFIED"
}

variable "service_component" {
  type    = string
  default = "NOT_IDENTIFIED" // Defined in IT Portal projects
}

variable "account_id" {
  type        = string
  description = "The ID of the working account"
}

variable "region" {
  description = "(Required) Region to deploy the resources to."
  type        = string
}

variable "ami_regions_kms_key" {
  description = "(Optional) A list of additional AWS Regions to share the AMI"
  type        = list(string)
  default     = []
}

variable "role_name" {
  type        = string
  description = "AWS role name to assume"
}


#####################################################################################################
#COMMON

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "mandatory_tags" {
  type = map(string)
}

variable "custom_tags" {
  type = map(string)
}

#####################################################################################################
#IMAGE BUILDER
variable "image_builder_config" {
  type = map(any)
}