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

# ═══════════════════════════════════════════
# UDR ROUTE TABLES
# Forces ALL spoke traffic through Firewall
# 0.0.0.0/0 → VirtualAppliance → Firewall IP
# ═══════════════════════════════════════════

# AVD Spoke Route Table
resource "azurerm_route_table" "avd" {
  name                          = "rt-spoke-avd-${local.environment}"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.spoke_avd.name
  bgp_route_propagation_enabled = false
  tags                          = local.common_tags

  route {
    name                   = "default-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
  }
}

# AI Spoke Route Table
resource "azurerm_route_table" "ai" {
  name                          = "rt-spoke-ai-${local.environment}"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.spoke_ai.name
  bgp_route_propagation_enabled = false
  tags                          = local.common_tags

  route {
    name                   = "default-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
  }
}

# Associate AVD Route Table to AVD Subnet
resource "azurerm_subnet_route_table_association" "avd" {
  subnet_id      = azurerm_subnet.avd_hosts.id
  route_table_id = azurerm_route_table.avd.id
}

# Associate AI Route Table to AI Subnet
resource "azurerm_subnet_route_table_association" "ai" {
  subnet_id      = azurerm_subnet.ai_services.id
  route_table_id = azurerm_route_table.ai.id
}

# ═══════════════════════════════════════════
# NETWORK SECURITY GROUPS
# Defence in depth - second security layer
# Firewall = perimeter, NSG = subnet level
# ═══════════════════════════════════════════

# AVD Hosts NSG
resource "azurerm_network_security_group" "avd_hosts" {
  name                = "nsg-avd-hosts-${local.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke_avd.name
  tags                = local.common_tags

  security_rule {
    name                       = "Allow-AVD-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "WindowsVirtualDesktop"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-RDP-From-Hub"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.hub_vnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG to AVD Subnet
resource "azurerm_subnet_network_security_group_association" "avd_hosts" {
  subnet_id                 = azurerm_subnet.avd_hosts.id
  network_security_group_id = azurerm_network_security_group.avd_hosts.id
}

# ═══════════════════════════════════════════
# MANAGED IDENTITY
# Zero credential authentication
# User Assigned = survives VM recreation
# ═══════════════════════════════════════════

resource "azurerm_user_assigned_identity" "avd" {
  name                = "mi-avd-${local.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  tags                = local.common_tags
}

# ═══════════════════════════════════════════
# KEY VAULT
# Zero public access - Private Endpoint only
# Managed Identity gets read access
# ═══════════════════════════════════════════

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "hub" {
  name                          = local.keyvault_name
  location                      = var.location
  resource_group_name           = azurerm_resource_group.hub.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false
  public_network_access_enabled = false
  enable_rbac_authorization     = true
  tags                          = local.common_tags
}

# Grant Managed Identity access to Key Vault secrets
resource "azurerm_role_assignment" "avd_kv_secrets" {
  scope                = azurerm_key_vault.hub.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.avd.principal_id
}

# ═══════════════════════════════════════════
# PRIVATE DNS ZONE + PRIVATE ENDPOINT
# Zero public access for Key Vault
# nslookup → 10.0.x.x proves Zero Trust
# ═══════════════════════════════════════════

# Private DNS Zone for Key Vault
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = local.common_tags
}

# Link DNS Zone to Hub VNet
resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "dns-link-hub-keyvault"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = local.common_tags
}

# Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "keyvault" {
  name                = "pe-keyvault-${local.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  subnet_id           = azurerm_subnet.hub_shared.id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-keyvault"
    private_connection_resource_id = azurerm_key_vault.hub.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-zone-group-keyvault"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
  }
}

# ═══════════════════════════════════════════
# AVD MODULE CALL
# Calls the AVD module we built
# ═══════════════════════════════════════════

module "avd" {
  source = "../../modules/avd"

  location            = var.location
  resource_group_name = azurerm_resource_group.spoke_avd.name
  host_pool_name      = "hp-avd-${local.environment}"
  workspace_name      = "ws-avd-${local.environment}"
  scaling_plan_name   = "sp-avd-${local.environment}"
  managed_identity_id = azurerm_user_assigned_identity.avd.id
  subnet_id           = azurerm_subnet.avd_hosts.id
  tags                = local.common_tags
}
