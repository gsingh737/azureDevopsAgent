// Resource group for the Azure VM and associated infrastructure
resource "azurerm_resource_group" "devops_rg" {
    name     = var.rg_name
    location = data.azurerm_resource_group.vnet_rg.location

    tags = {
        purpose = "DevOps Self-Hosted Agent"
    }
}

// Network interface card for the Azure VM.
resource "azurerm_network_interface" "devops_vm_nic" {
    name                        = "${var.vm_name}-nic-${format("%03d", count.index + 1)}"
    location                    = azurerm_resource_group.devops_rg.location
    resource_group_name         = var.rg_name

    ip_configuration {
        name                          = "${var.vm_name}NicConfig"
        subnet_id                     = data.azurerm_subnet.devops_subnet.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "${cidrhost(data.azurerm_subnet.devops_subnet.address_prefix, 10 + count.index)}"
        # public_ip_address_id        = azurerm_public_ip.devops_public_ip.id  // Remove this if no public ip is required.
    }

    count                           = var.vm_count
    tags = azurerm_resource_group.devops_rg.tags

}

// Connect the security group to the network interface
# resource "azurerm_network_interface_security_group_association" "devops_vm_nic" {
#     network_interface_id      = azurerm_network_interface.devops_vm_nic.id
#     network_security_group_id = data.azurerm_network_security_group.devops_nsg.id
# }



resource "azurerm_availability_set" "avset" {
 name                         = var.avset_name
 location                     = azurerm_resource_group.devops_rg.name
 resource_group_name          = azurerm_resource_group.devops_rg.name
}


// Azure VM to be used for hosting the Azure Pipelines agent
resource "azurerm_linux_virtual_machine" "devops_vm" {
    count                 = var.vm_count
    name                  = "${var.vm_name}-${format("%03d", count.index + 1)}"
    location              = azurerm_resource_group.devops_rg.location
    resource_group_name   = azurerm_resource_group.devops_rg.name
    availability_set_id   = azurerm_availability_set.avset.id
    network_interface_ids = [azurerm_network_interface.devops_vm_nic[count.index].id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "${var.vm_name}OsDisk${format("%03d", count.index + 1)}"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = var.vm_name
    admin_username = "azuredevopsuser"
    disable_password_authentication = true

    admin_ssh_key {
        username       = "azuredevopsuser"
        public_key     = var.ssh_pub_key
    }

    boot_diagnostics {
        storage_account_uri = data.azurerm_storage_account.devops_vm_stor.primary_blob_endpoint
    }

    custom_data    = base64encode("${data.template_file.linux-vm-cloud-init.rendered}")

    tags = azurerm_resource_group.devops_rg.tags
}
