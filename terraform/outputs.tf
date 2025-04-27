output "master_ip" {
  value = module.k3s_cluster.master_public_ip
}

output "worker_ips" {
  value = module.k3s_cluster.workers_public_ips
}
