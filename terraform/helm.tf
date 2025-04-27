resource "null_resource" "update_helm_cache" {
  depends_on = [aws_instance.master]

  provisioner "local-exec" {
    command     = <<-EOT
      mkdir -p "$HOME/.helm/repository"
      helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
      helm repo add jetstack https://charts.jetstack.io
      helm repo add argo          https://argoproj.github.io/argo-helm
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
    value = "ClusterIP"
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
###############################################################################
# Argo CD chart (argo/argo-cd) en namespace "argocd"
###############################################################################
resource "helm_release" "argocd" {
  name             = "argocd"
  chart            = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  version          = "5.55.0"
  namespace        = "argocd"
  create_namespace = true

  # Exponemos el server de Argo CD por NodePort
  set {
    name  = "server.service.type"
    value = "NodePort"
  }
  set {
    # puerto HTTP interno de Argo CD → NodePort 30081
    name  = "server.service.nodePort"
    value = "30081"
  }



  # Exponemos el server de Argo CD por HTTPS
  set {
    name  = "server.ingress.enabled"
    value = "false"
  }
}
