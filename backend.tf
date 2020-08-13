terraform {
  backend "azurerm" {
    resource_group_name   = var.tf_state_store_rg
    storage_account_name  = var.tf_state_store_name
    container_name        = var.tf_state_container_name
    key                   = var.tf_state_key_file
  }
}
