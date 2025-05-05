output "proxy_public_ip" {
  value = aws_instance.ec2-proxy.public_ip
}

output "ssh_proxy_command" {
  description = "SSH command to connect to the proxy node"
  # Assuming the same key 'k3s_key.pem' is used for the proxy
  value = "ssh -i ec2-proxy-key.pem ec2-user@${aws_instance.ec2-proxy.public_ip}"
}
