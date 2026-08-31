# Azure Container Apps is used instead of an App Service Plan because
# App Service requires a reserved VM quota that new or trial
# subscriptions frequently have set to zero (this is the "Unauthorized,
# additional quota" error). Container Apps runs on a consumption model
# and does not hit that same quota check, which makes it the more
# reliable choice for a demo environment.

resource "azurerm_container_app_environment" "main" {
  name                = "cae-${var.project_name}-${var.environment}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_container_app" "main" {
  name                         = "app-${var.project_name}-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = data.azurerm_resource_group.main.name
  revision_mode                = "Single"

  # System assigned identity lets this app authenticate to other Azure
  # resources, for example the storage account below, without any
  # connection string or key stored in app settings.
  identity {
    type = "SystemAssigned"
  }

  template {
    container {
      name   = "app"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    external_enabled = true
    target_port      = 80

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

# RBAC: grant the container app's managed identity read access to the
# storage container it needs, scoped to the storage account, nothing
# wider than that.
resource "azurerm_role_assignment" "app_storage_reader" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_container_app.main.identity[0].principal_id
}
