terraform {
  backend "azurerm" {
    resource_group_name   = "terraform-backend-self-hosted-rg"
    storage_account_name  = "storageacctsaagent"
    container_name        = "storagecontaineragent"
    key                   = "terraform.tfstate"
  }
}
