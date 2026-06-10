output "ec2_public_ip" {
  value = aws_eip.this.public_ip
}

output "ec2_private_ip" {
  value = aws_instance.this.private_ip
}

output "ssh_command" {
  value = "ssh ${var.ssh_username}@${aws_eip.this.public_ip}"
}

output "deploy_ssh_command" {
  value = "ssh ${var.deploy_username}@${aws_eip.this.public_ip}"
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}

output "rds_port" {
  value = aws_db_instance.postgres.port
}

output "rds_ssh_tunnel_command" {
  value = "ssh -N -L 5432:${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port} ${var.ssh_username}@${aws_eip.this.public_ip}"
}
