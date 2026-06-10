output "vm_public_ip" {
  value = azurerm_public_ip.vm.ip_address
}

output "vm_fqdn" {
  value = azurerm_public_ip.vm.fqdn
}

output "vm_private_ip" {
  value = azurerm_network_interface.vm.private_ip_address
}

output "ssh_command" {
  value = "ssh ${var.admin_username}@${azurerm_public_ip.vm.fqdn}"
}

output "deploy_ssh_command" {
  value = "ssh ${var.deploy_username}@${azurerm_public_ip.vm.fqdn}"
}

output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.postgres.fqdn
}

output "postgres_ssh_tunnel_command" {
  value = "ssh -N -L 5432:${azurerm_postgresql_flexible_server.postgres.fqdn}:5432 ${var.admin_username}@${azurerm_public_ip.vm.fqdn}"
}
