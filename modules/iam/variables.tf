variable "role_name" {
  type = string
}

variable "assume_role_services" {
  type = list(string)
}

variable "policy_name" {
  type = string
}

variable "inline_policy_statements" {
  type = list(object({
    Effect = string
    Action   = list(string)
    Resource = list(string)
    Condition = optional(map(map(string))) 
  }))
  default = []
}

variable "managed_policy_arns" {
  type = list(string)
  default = []
}

variable "tags" {
  type = map(string)
  default = {}
}

