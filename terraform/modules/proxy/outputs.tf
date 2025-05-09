output "proxy_public_ip" {
  value = aws_instance.ec2-proxy.public_ip
}

output "ssh_proxy_command" {
  description = "SSH command to connect to the proxy node"
  # Assuming the same key 'k3s_key.pem' is used for the proxy
  value = "ssh -i ec2-proxy-key.pem ec2-user@${aws_instance.ec2-proxy.public_ip}"
}

output "proxy_private_key_pem" {
  value     = tls_private_key.ec2-proxy.private_key_pem
  sensitive = true
}
