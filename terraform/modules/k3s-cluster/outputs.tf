output "master_public_ip" {
  value = aws_instance.master.public_ip
}
output "master_private_ip" {
  value = aws_instance.master.private_ip
}

output "workers_public_ips" {
  value = aws_instance.workers[*].public_ip
}

output "private_key_pem" {
  value     = tls_private_key.k3s.private_key_pem
  sensitive = true
}

output "ssh_master_command" {
  description = "SSH command to connect to the master node"
  value       = "ssh -i k3s-key.pem ubuntu@${aws_instance.master.public_ip}"
}

output "ssh_worker_commands" {
  description = "SSH commands to connect to the worker nodes"
  value       = [for ip in aws_instance.workers[*].public_ip : "ssh -i k3s-key.pem ubuntu@${ip}"]
}
