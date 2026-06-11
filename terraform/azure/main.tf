provider "azurerm" {
  features {}
}

locals {
  name                = var.project
  resource_group_name = var.resource_group_name

  deploy_user_cloud_config = yamlencode({
    users = [
      {
        name        = var.deploy_username
        groups      = "users"
        shell       = "/bin/bash"
        lock_passwd = true
        # Keep cloud-init stable for existing VMs. Add extra deploy-user keys manually to avoid forcing VM replacement.
        ssh_authorized_keys = [var.deploy_ssh_public_key]
      }
    ]
  })

  tags = {
    Project   = var.project
    ManagedBy = "terraform"
  }
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.resource_group_location
  tags     = local.tags
}

resource "azurerm_virtual_network" "this" {
  name                = "${local.name}-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.vnet_cidr]
  tags                = local.tags
}

resource "azurerm_subnet" "vm" {
  name                 = "${local.name}-vm-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.vm_subnet_cidr]
}

resource "azurerm_subnet" "db" {
  name                 = "${local.name}-db-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.db_subnet_cidr]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "postgresql-flexible-server"

    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_network_security_group" "vm" {
  name                = "${local.name}-vm-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  security_rule {
    name                       = "AllowSshFromInternet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowWebFromInternet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "db" {
  name                = "${local.name}-db-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  security_rule {
    name                       = "AllowPostgreSqlFromVmSubnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = var.vm_subnet_cidr
    destination_address_prefix = var.db_subnet_cidr
  }
}

resource "azurerm_subnet_network_security_group_association" "vm" {
  subnet_id                 = azurerm_subnet.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

resource "azurerm_subnet_network_security_group_association" "db" {
  subnet_id                 = azurerm_subnet.db.id
  network_security_group_id = azurerm_network_security_group.db.id
}

resource "azurerm_public_ip" "vm" {
  name                = "${local.name}-vm-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.project
  tags                = local.tags
}

resource "azurerm_network_interface" "vm" {
  name                = "${local.name}-vm-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "${local.name}-vm"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  size                = var.vm_size
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.vm.id
  ]

  disable_password_authentication = true
  custom_data                     = base64encode("#cloud-config\n${local.deploy_user_cloud_config}")
  tags                            = local.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_storage_account_type
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.ubuntu_image_publisher
    offer     = var.ubuntu_image_offer
    sku       = var.ubuntu_image_sku
    version   = var.ubuntu_image_version
  }
}

resource "azurerm_private_dns_zone" "postgres" {
  name                = "${local.name}.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "${local.name}-postgres-dns-link"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.this.id
  tags                  = local.tags
}

resource "azurerm_postgresql_flexible_server" "postgres" {
  name                          = var.postgres_server_name
  resource_group_name           = azurerm_resource_group.this.name
  location                      = var.location
  version                       = var.postgres_version
  delegated_subnet_id           = azurerm_subnet.db.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id
  public_network_access_enabled = false
  administrator_login           = var.db_username
  administrator_password        = var.db_password
  sku_name                      = var.postgres_sku_name
  storage_mb                    = var.postgres_storage_mb
  backup_retention_days         = 7
  zone                          = var.postgres_zone
  tags                          = local.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}
