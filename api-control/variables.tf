#  ###### Application Account ######

variable "application_account_region" {
  description = "Region where the resources should be deployed in the application account"
  default     = "us-west-2"
  type        = string
}

variable "application_account_role_arn" {
  description = "ARN of a role in the application account to assume (with permissions to deploy resources)"
  type        = string
  default     = ""
}

variable "application_account_external_id" {
  description = "External id of the application Role"
  type        = string
  default     = ""
}

#  ############# Stack #############

variable "customer_name" {
  description = "Name of the customer. This will be used on resources tags"
  default     = "dev"
  type        = string
}

variable "environment" {
  description = "Environment to tag the resources"
  default     = "dev"
  type        = string
}

variable "certificate" {
  description = "Certificate for SSL connections"
  type = string
}