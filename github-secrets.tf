resource "github_actions_secret" "kubeconfig_data" {
  repository      = "proyecto_intranet"
  secret_name     = "KUBECONFIG_DATA"
  plaintext_value = filebase64("../kubeconfig")
}
