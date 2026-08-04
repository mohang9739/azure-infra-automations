# ═══════════════════════════════════════════
# RESOURCE GROUPS
# Three RGs aligned to Hub-Spoke topology
# ═══════════════════════════════════════════

resource "azurerm_resource_group" "hub" {
  name     = local.hub_rg_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "spoke_avd" {
  name     = local.avd_rg_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "spoke_ai" {
  name     = local.ai_rg_name
  location = var.location
  tags     = local.common_tags
}
