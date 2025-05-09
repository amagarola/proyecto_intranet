resource "github_actions_secret" "aws_access_key" {
  repository      = "proyecto_intranet"
  secret_name     = "AWS_ACCESS_KEY_ID"
  plaintext_value = var.aws_access_key
}

resource "github_actions_secret" "aws_secret_key" {
  repository      = "proyecto_intranet"
  secret_name     = "AWS_SECRET_ACCESS_KEY"
  plaintext_value = var.aws_secret_key
}

resource "github_actions_variable" "master_private_ip" {
  repository    = "proyecto_intranet"
  variable_name = "master_private_ip"
  value         = var.master_private_ip
}

resource "github_actions_variable" "proxy_public_ip" {
  repository    = "proyecto_intranet"
  variable_name = "proxy_public_ip"
  value         = var.proxy_public_ip
}

resource "github_actions_variable" "target_port_http" {
  repository    = "proyecto_intranet"
  variable_name = "TARGET_PORT_HTTP"
  value         = var.target_port_http
}

resource "github_actions_variable" "target_port_https" {
  repository    = "proyecto_intranet"
  variable_name = "TARGET_PORT_HTTPS"
  value         = var.target_port_https
}

resource "github_actions_variable" "domain" {
  repository    = "proyecto_intranet"
  variable_name = "DOMAIN"
  value         = var.domain
}

resource "github_actions_secret" "k3s_private_key" {
  repository      = "proyecto_intranet"
  secret_name     = "K3S_PRIVATE_KEY"
  plaintext_value = file("${path.module}/modules/k3s-cluster/k3s-key.pem")
}

resource "github_actions_secret" "proxy_private_key" {
  repository      = "proyecto_intranet"
  secret_name     = "PROXY_PRIVATE_KEY"
  plaintext_value = file("${path.module}/modules/proxy/ec2-proxy-key.pem")
}
