output "helm_release_names" {
  value = [
    helm_release.nginx_ingress.name,
    helm_release.cert_manager.name,
    helm_release.argocd.name,
    # helm_release.wordpress.name,
  ]
}
