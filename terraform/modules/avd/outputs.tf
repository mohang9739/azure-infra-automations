output "host_pool_id" {
  value       = azurerm_virtual_desktop_host_pool.this.id
  description = "AVD Host Pool ID"
}

output "host_pool_name" {
  value       = azurerm_virtual_desktop_host_pool.this.name
  description = "AVD Host Pool name"
}

output "registration_token" {
  value       = azurerm_virtual_desktop_host_pool_registration_info.this.token
  description = "Registration token for DSC extension"
  sensitive   = true
}

output "workspace_id" {
  value       = azurerm_virtual_desktop_workspace.this.id
  description = "AVD Workspace ID"
}

output "application_group_id" {
  value       = azurerm_virtual_desktop_application_group.this.id
  description = "AVD Application Group ID"
}
