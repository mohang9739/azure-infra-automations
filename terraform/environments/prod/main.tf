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

# ═══════════════════════════════════════════
# VIRTUAL NETWORKS
# Three VNets - Hub-Spoke topology
# Non-overlapping CIDRs for peering
# ═══════════════════════════════════════════

resource "azurerm_virtual_network" "hub" {
  name                = local.hub_vnet_name
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = [var.hub_vnet_cidr]
  tags                = local.common_tags
}

resource "azurerm_virtual_network" "spoke_avd" {
  name                = local.avd_vnet_name
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke_avd.name
  address_space       = [var.avd_vnet_cidr]
  tags                = local.common_tags
}

resource "azurerm_virtual_network" "spoke_ai" {
  name                = local.ai_vnet_name
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke_ai.name
  address_space       = [var.ai_vnet_cidr]
  tags                = local.common_tags
}
