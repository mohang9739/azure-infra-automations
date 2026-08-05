# Azure Region
location = "eastus"

# Hub VNet - Central network
# All shared services live here
hub_vnet_cidr = "10.0.0.0/16"

# AVD Spoke - Desktop workloads
avd_vnet_cidr = "10.1.0.0/16"

# AI Spoke - AI services
ai_vnet_cidr = "10.2.0.0/16"

# Hub Subnets
firewall_subnet_cidr   = "10.0.1.0/24"
hub_shared_subnet_cidr = "10.0.3.0/24"

# AVD Subnet
avd_hosts_subnet_cidr = "10.1.1.0/24"

# AI Subnet
ai_services_subnet_cidr = "10.2.1.0/24"
