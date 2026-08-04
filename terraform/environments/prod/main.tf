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

# ═══════════════════════════════════════════
# SUBNETS
# Carved from VNet address spaces
# AzureFirewallSubnet = mandatory name
# ═══════════════════════════════════════════

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.firewall_subnet_cidr]
}

resource "azurerm_subnet" "hub_shared" {
  name                 = "snet-hub-shared"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.hub_shared_subnet_cidr]
}

resource "azurerm_subnet" "avd_hosts" {
  name                 = "snet-avd-hosts"
  resource_group_name  = azurerm_resource_group.spoke_avd.name
  virtual_network_name = azurerm_virtual_network.spoke_avd.name
  address_prefixes     = [var.avd_hosts_subnet_cidr]
}

resource "azurerm_subnet" "ai_services" {
  name                 = "snet-ai-services"
  resource_group_name  = azurerm_resource_group.spoke_ai.name
  virtual_network_name = azurerm_virtual_network.spoke_ai.name
  address_prefixes     = [var.ai_services_subnet_cidr]
}

# ═══════════════════════════════════════════
# VNET PEERINGS
# Hub-Spoke requires BOTH directions
# Non-transitive by Azure design
# Spoke-to-Spoke traffic via Firewall
# ═══════════════════════════════════════════

# Hub → AVD Spoke
resource "azurerm_virtual_network_peering" "hub_to_avd" {
  name                      = "peer-hub-to-avd"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_avd.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}

# AVD Spoke → Hub
resource "azurerm_virtual_network_peering" "avd_to_hub" {
  name                      = "peer-avd-to-hub"
  resource_group_name       = azurerm_resource_group.spoke_avd.name
  virtual_network_name      = azurerm_virtual_network.spoke_avd.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}

# Hub → AI Spoke
resource "azurerm_virtual_network_peering" "hub_to_ai" {
  name                      = "peer-hub-to-ai"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_ai.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}

# AI Spoke → Hub
resource "azurerm_virtual_network_peering" "ai_to_hub" {
  name                      = "peer-ai-to-hub"
  resource_group_name       = azurerm_resource_group.spoke_ai.name
  virtual_network_name      = azurerm_virtual_network.spoke_ai.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}


# ═══════════════════════════════════════════
# VNET PEERINGS
# Hub-Spoke requires BOTH directions
# Non-transitive by Azure design

# ═══════════════════════════════════════════
# AZURE FIREWALL PREMIUM
# Central inspection point for Hub-Spoke
# Most expensive resource - destroy after test
# ═══════════════════════════════════════════

# Step 1: Public IP for Firewall
resource "azurerm_public_ip" "firewall" {
  name                = "pip-${local.firewall_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

# Step 2: Firewall Policy
resource "azurerm_firewall_policy" "hub" {
  name                     = "afwp-hub-${local.environment}"
  location                 = var.location
  resource_group_name      = azurerm_resource_group.hub.name
  sku                      = "Premium"
  threat_intelligence_mode = "Alert"
  tags                     = local.common_tags
}

# Step 3: Azure Firewall Premium
resource "azurerm_firewall" "hub" {
  name                = local.firewall_name
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Premium"
  firewall_policy_id  = azurerm_firewall_policy.hub.id
  tags                = local.common_tags

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}
