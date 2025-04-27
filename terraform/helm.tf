resource "null_resource" "update_helm_cache" {
  depends_on = [aws_instance.master]

  provisioner "local-exec" {
    command     = <<-EOT
      mkdir -p "$HOME/.helm/repository"
      helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
      helm repo add jetstack https://charts.jetstack.io
      helm repo update
    EOT
    interpreter = ["powershell", "-Command"]
  }
}

resource "helm_release" "nginx_ingress" {
  depends_on       = [null_resource.update_helm_cache]
  name             = "ingress-nginx"
  repository       = "ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.7.1"
  namespace        = "ingress-nginx"
  create_namespace = true
  force_update     = true
  cleanup_on_fail  = true

  set {
    name  = "controller.service.type"
    value = "NodePort"
  }
  set {
    name  = "controller.service.nodePorts.http"
    value = "30080"
  }
  set {
    name  = "controller.service.nodePorts.https"
    value = "30443"
  }
}

resource "helm_release" "cert_manager" {
  depends_on       = [null_resource.update_helm_cache]
  name             = "cert-manager"
  repository       = "jetstack"
  chart            = "cert-manager"
  version          = "v1.13.2"
  namespace        = "cert-manager"
  create_namespace = true
  force_update     = true
  cleanup_on_fail  = true

  # -- Instalar los CRDs de cert-manager
  set {
    name  = "installCRDs"
    value = "true"
  }

  # -- Desactivar el Job startupapicheck
  set {
    name  = "startupapicheck.enabled"
    value = "false"
  }
}
