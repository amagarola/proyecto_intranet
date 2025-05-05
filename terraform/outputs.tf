output "ssh_master_command" {
  description = "SSH command to connect to the master node"
  value       = module.k3s_cluster.ssh_master_command
}

output "ssh_worker_commands" {
  description = "SSH commands to connect to the worker nodes"
  value       = module.k3s_cluster.ssh_worker_commands
}

output "k3s_private_key_pem" {
  description = "Private key to connect to the nodes"
  value       = module.k3s_cluster.private_key_pem
  sensitive   = true
}

output "master_public_ip" {
  description = "Public IP address of the master node"
  value       = module.k3s_cluster.master_public_ip
}

output "master_private_ip" {
  description = "Private IP address of the master node"
  value       = module.k3s_cluster.master_private_ip
}

output "workers_public_ips" {
  description = "Public IP addresses of the worker nodes"
  value       = module.k3s_cluster.workers_public_ips
}

output "proxy_public_ip" {
  description = "Public IP address of the proxy node"
  value       = module.proxy.proxy_public_ip
}

output "ssh_proxy_command" {
  description = "SSH command to connect to the proxy node"
  value       = module.proxy.ssh_proxy_command
}
