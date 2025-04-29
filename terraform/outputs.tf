output "master_ip" {
  value = module.k3s_cluster.master_public_ip
}

output "master_ip_private" {
  value = module.k3s_cluster.master_private_ip
}

output "worker_ips" {
  value = module.k3s_cluster.workers_public_ips
}
output "proxy_ip" {
  value = module.proxy.proxy_public_ip
}
