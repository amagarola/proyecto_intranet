resource "null_resource" "update_helm_cache" {
  provisioner "local-exec" {
    command     = <<-EOT
      mkdir -p "$HOME/.helm/repository"
      helm repo add jetstack https://charts.jetstack.io
      helm repo add argo          https://argoproj.github.io/argo-helm
      helm repo update
    EOT
    interpreter = ["powershell", "-Command"]
  }
}


###############################################################################


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
  values = [
    yamlencode({
      extraManifests = [
        <<-EOT
        apiVersion: cert-manager.io/v1
        kind: ClusterIssuer
        metadata:
          name: letsencrypt-prod
        spec:
          acme:
            email: adrianmagarola@gmail.co
            server: https://acme-v02.api.letsencrypt.org/directory
            privateKeySecretRef:
              name: letsencrypt-prod
            solvers:
            - http01:
                ingress:
                  class: traefik
        EOT
      ]
    })
  ]
}
###############################################################################
# Argo CD chart (argo/argo-cd) en namespace "argocd"
###############################################################################
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.55.0"
  namespace        = "argocd"
  create_namespace = true

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  # Habilitar Ingress y asociar al host
  set {
    name  = "server.ingress.enabled"
    value = "true"
  }
  set {
    name  = "server.ingress.ingressClassName"
    value = "traefik"
  }
  set {
    name  = "server.ingress.hosts[0]"
    value = "argocd.adrianmagarola.click"
  }
  set {
    name  = "server.ingress.paths[0]"
    value = "/"
  }

  # TLS usando cert-manager ClusterIssuer
  set {
    name  = "server.ingress.annotations.cert-manager\\.io/cluster-issuer"
    value = "letsencrypt-prod"
  }
  set {
    name  = "server.ingress.tls[0].hosts[0]"
    value = "argocd.adrianmagarola.click"
  }
  set {
    name  = "server.ingress.tls[0].secretName"
    value = "argocd-tls"
  }
}
###############################################################################
resource "helm_release" "letsencrypt_issuer" {
  name             = "letsencrypt-issuer"
  namespace        = "cert-manager"
  create_namespace = false
  chart            = "${path.module}/charts/letsencrypt-issuer"

  depends_on = [
    helm_release.cert_manager,
    # helm_release.nginx_ingress
  ]
}
###############################################################################
