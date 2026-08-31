output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "container_app_fqdn" {
  description = "Public hostname of the deployed Container App"
  value       = azurerm_container_app.main.latest_revision_fqdn
}

output "container_app_identity_principal_id" {
  description = "Principal ID of the Container App system assigned managed identity"
  value       = azurerm_container_app.main.identity[0].principal_id
}

output "storage_account_name" {
  description = "Name of the storage account backing the app"
  value       = azurerm_storage_account.main.name
}
