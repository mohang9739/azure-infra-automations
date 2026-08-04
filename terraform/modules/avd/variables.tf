variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for AVD resources"
}

variable "host_pool_name" {
  type        = string
  description = "AVD Host Pool name"
}

variable "workspace_name" {
  type        = string
  description = "AVD Workspace name"
}

variable "scaling_plan_name" {
  type        = string
  description = "AVD Scaling Plan name"
}

variable "managed_identity_id" {
  type        = string
  description = "User Assigned Managed Identity ID"
}

variable "subnet_id" {
  type        = string
  description = "AVD hosts subnet ID"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
}
