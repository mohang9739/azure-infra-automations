variable "location" {
  type        = string
  description = "Azure region for all resources"
}

variable "hub_vnet_cidr" {
  type        = string
  description = "Hub VNet address space"
}

variable "avd_vnet_cidr" {
  type        = string
  description = "AVD Spoke VNet address space"
}

variable "ai_vnet_cidr" {
  type        = string
  description = "AI Spoke VNet address space"
}

variable "firewall_subnet_cidr" {
  type        = string
  description = "Azure Firewall dedicated subnet"
}

variable "hub_shared_subnet_cidr" {
  type        = string
  description = "Hub shared services subnet"
}

variable "avd_hosts_subnet_cidr" {
  type        = string
  description = "AVD session host subnet"
}

variable "ai_services_subnet_cidr" {
  type        = string
  description = "AI services subnet"
}
