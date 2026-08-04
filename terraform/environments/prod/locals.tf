locals {
  # Project metadata
  project     = "azure-infra"
  environment = "prod"
  owner       = "mohan"
  location    = "eastus"

  # Common tags applied to every resource
  common_tags = {
    project     = local.project
    environment = local.environment
    owner       = local.owner
    managed_by  = "terraform"
    repo        = "github.com/mohang9739/azure-infra-automation"
  }

  # Naming conventions
  hub_vnet_name     = "vnet-hub-${local.environment}"
  avd_vnet_name     = "vnet-spoke-avd-${local.environment}"
  ai_vnet_name      = "vnet-spoke-ai-${local.environment}"
  hub_rg_name       = "rg-hub-${local.environment}"
  avd_rg_name       = "rg-spoke-avd-${local.environment}"
  ai_rg_name        = "rg-spoke-ai-${local.environment}"
  firewall_name     = "afw-hub-${local.environment}"
  keyvault_name     = "kv-${local.project}-${local.environment}"
}
