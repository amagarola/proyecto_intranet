output "proxy_public_ip" {
  value = aws_instance.ec2-proxy.public_ip
}
