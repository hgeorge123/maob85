variable "target_eventbus_arn" {
  type = string
}

variable "target_role_arn" {
  type = string
} 

variable "mandatory_tags" {
  type = map(string)
}
