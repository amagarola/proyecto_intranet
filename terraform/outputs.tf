
output "master_ip" {
  value = aws_instance.master.public_ip
}

output "worker_ips" {
  value = [for i in aws_instance.workers : i.public_ip]
}

# output "nginx_ingress_lb" {
#   value       = helm_release.nginx_ingress.status[0].load_balancer[0].ingress[0].hostname
#   description = "DNS del Load Balancer para el Ingress Controller"
# }
