# ═══════════════════════════════════════════
# AVD WORKSPACE
# User-facing portal for desktop access
# ═══════════════════════════════════════════

resource "azurerm_virtual_desktop_workspace" "this" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  friendly_name       = "Azure Virtual Desktop"
  description         = "Enterprise AVD Workspace"
  tags                = var.tags
}

# ═══════════════════════════════════════════
# AVD HOST POOL
# Pooled BreadthFirst = shared VMs
# ═══════════════════════════════════════════

resource "azurerm_virtual_desktop_host_pool" "this" {
  name                     = var.host_pool_name
  location                 = var.location
  resource_group_name      = var.resource_group_name
  type                     = "Pooled"
  load_balancer_type       = "BreadthFirst"
  validate_environment     = false
  start_vm_on_connect      = true
  custom_rdp_properties    = "audiocapturemode:i:1;audiomode:i:0;"
  maximum_sessions_allowed = 10
  tags                     = var.tags
}

# ═══════════════════════════════════════════
# REGISTRATION INFO
# Token for DSC extension to register VMs
# Expires after 48 hours
# ═══════════════════════════════════════════

resource "azurerm_virtual_desktop_host_pool_registration_info" "this" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.this.id
  expiration_date = timeadd(timestamp(), "48h")
}

# ═══════════════════════════════════════════
# APPLICATION GROUP
# Desktop application group for users
# ═══════════════════════════════════════════

resource "azurerm_virtual_desktop_application_group" "this" {
  name                = "dag-${var.host_pool_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = "Desktop"
  host_pool_id        = azurerm_virtual_desktop_host_pool.this.id
  friendly_name       = "Desktop Application Group"
  tags                = var.tags
}

# ═══════════════════════════════════════════
# WORKSPACE + APP GROUP ASSOCIATION
# Links workspace to application group
# ═══════════════════════════════════════════

resource "azurerm_virtual_desktop_workspace_application_group_association" "this" {
  workspace_id         = azurerm_virtual_desktop_workspace.this.id
  application_group_id = azurerm_virtual_desktop_application_group.this.id
}

# ═══════════════════════════════════════════
# SCALING PLAN
# 8AM ramp up → 7PM ramp down
# Source of 40% cost reduction
# ═══════════════════════════════════════════

resource "azurerm_virtual_desktop_scaling_plan" "this" {
  name                = var.scaling_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  friendly_name       = "AVD Scaling Plan"
  time_zone           = "India Standard Time"
  tags                = var.tags

  schedule {
    name                                 = "weekdays"
    days_of_week                         = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    ramp_up_start_time                   = "08:00"
    ramp_up_load_balancing_algorithm     = "BreadthFirst"
    ramp_up_minimum_hosts_percent        = 20
    ramp_up_capacity_threshold_percent   = 60
    peak_start_time                      = "09:00"
    peak_load_balancing_algorithm        = "BreadthFirst"
    ramp_down_start_time                 = "19:00"
    ramp_down_load_balancing_algorithm   = "DepthFirst"
    ramp_down_minimum_hosts_percent      = 10
    ramp_down_force_logoff_users         = false
    ramp_down_wait_time_minutes          = 45
    ramp_down_notification_message       = "Session ending in 45 minutes. Please save your work."
    ramp_down_capacity_threshold_percent = 90
    ramp_down_stop_hosts_when            = "ZeroActiveSessions"
    off_peak_start_time                  = "20:00"
    off_peak_load_balancing_algorithm    = "DepthFirst"
  }

  host_pool {
    hostpool_id          = azurerm_virtual_desktop_host_pool.this.id
    scaling_plan_enabled = true
  }
}
