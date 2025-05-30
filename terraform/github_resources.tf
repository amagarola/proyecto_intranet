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
  value         = module.k3s_cluster.master_private_ip
}

resource "github_actions_variable" "proxy_public_ip" {
  repository    = "proyecto_intranet"
  variable_name = "proxy_public_ip"
  value         = module.proxy.proxy_public_ip
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

resource "github_actions_variable" "domains" {
  repository    = "proyecto_intranet"
  variable_name = "DOMAINS"
  value         = join(",", var.domains)
}

resource "github_actions_secret" "k3s_private_key" {
  repository      = "proyecto_intranet"
  secret_name     = "K3S_PRIVATE_KEY"
  plaintext_value = module.k3s_cluster.private_key_pem
}

resource "github_actions_secret" "proxy_private_key" {
  repository      = "proyecto_intranet"
  secret_name     = "PROXY_PRIVATE_KEY"
  plaintext_value = module.proxy.proxy_private_key_pem
}
