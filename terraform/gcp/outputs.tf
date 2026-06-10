output "vm_public_ip" {
  value = google_compute_address.vm.address
}

output "vm_private_ip" {
  value = google_compute_instance.vm.network_interface[0].network_ip
}

output "ssh_command" {
  value = "ssh ${var.ssh_username}@${google_compute_address.vm.address}"
}

output "deploy_ssh_command" {
  value = "ssh ${var.deploy_username}@${google_compute_address.vm.address}"
}

output "cloud_sql_instance_name" {
  value = google_sql_database_instance.postgres.name
}

output "cloud_sql_private_ip" {
  value = google_sql_database_instance.postgres.private_ip_address
}

output "cloud_sql_ssh_tunnel_command" {
  value = "ssh -N -L 5432:${google_sql_database_instance.postgres.private_ip_address}:5432 ${var.ssh_username}@${google_compute_address.vm.address}"
}
