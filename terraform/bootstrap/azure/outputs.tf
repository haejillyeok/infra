output "backend_config" {
  value = {
    resource_group_name  = azurerm_resource_group.terraform_state.name
    storage_account_name = azurerm_storage_account.terraform_state.name
    container_name       = azurerm_storage_container.terraform_state.name
    key                  = "haejillyeok/azure/terraform.tfstate"
    use_azuread_auth     = true
  }
}
