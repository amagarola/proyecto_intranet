output "helm_release_names" {
  value = [
    helm_release.nginx_ingress.name,
    helm_release.cert_manager.name,
    helm_release.argocd.name,
    # helm_release.wordpress.name,
  ]
}


output "argo_url" {
  description = "Acceso a ArgoCD con HTTPS"
  value       = "https://argocd.adrianmagarola.click"
}

# output "wordpress_url" {
#   description = "Acceso a WordPress con HTTPS"
#   value       = "https://adrianmagarola.click"
# }
