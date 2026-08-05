output "hub_vnet_id" {
  value       = azurerm_virtual_network.hub.id
  description = "Hub VNet ID"
}

output "firewall_private_ip" {
  value       = azurerm_firewall.hub.ip_configuration[0].private_ip_address
  description = "Firewall private IP for UDR"
}

output "keyvault_uri" {
  value       = azurerm_key_vault.hub.vault_uri
  description = "Key Vault URI"
}

output "managed_identity_id" {
  value       = azurerm_user_assigned_identity.avd.id
  description = "Managed Identity ID"
}

output "avd_host_pool_name" {
  value       = module.avd.host_pool_name
  description = "AVD Host Pool name"
}

output "avd_workspace_id" {
  value       = module.avd.workspace_id
  description = "AVD Workspace ID"
}
