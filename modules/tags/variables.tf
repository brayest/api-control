variable "name" {
  type        = string
  default     = ""
  description = "Name  (e.g. `bastion`, `dmz`, etc.)."
}

variable "stack" {
  type        = string
  default     = ""
  description = "Stack name (e.g. `client`, `dcs`, etc)."
}

variable "customer" {
  type        = string
  default     = ""
  description = "Customer name (e.g. `client`, `fis`, etc.)."
}

variable "environment" {
  type        = string
  default     = ""
  description = "Environment (e.g. `prod`, `dev`, `uat`)."
}

variable "order" {
  type        = list
  default     = ["stack", "customer", "environment", "name"]
  description = "Order vars for id, e.g. `name`,`environment`, etc."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. map(`Team`,`DevOps`)."
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `name`, `environment`, etc."
}
