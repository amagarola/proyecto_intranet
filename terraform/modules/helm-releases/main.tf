resource "null_resource" "update_helm_cache" {
  provisioner "local-exec" {
    command     = <<-EOT
      mkdir -p "$HOME/.helm/repository"
      helm repo add jetstack https://charts.jetstack.io
      helm repo add argo          https://argoproj.github.io/argo-helm
      helm repo update
    EOT
    interpreter = ["/bin/bash", "-c"]
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
          name: letsencrypt
        spec:
          acme:
            email: adrianmagarola@gmail.com
            server: https://acme-v02.api.letsencrypt.org/directory
            privateKeySecretRef:
              name: letsencrypt
            solvers:
            - http01:
                ingress:
                  class: nginx
        EOT
      ]
    })
  ]
}
###############################################################################
# Argo CD chart (argo/argo-cd) en namespace "argocd"
###############################################################################
resource "helm_release" "argocd" {
  depends_on       = [null_resource.update_helm_cache]
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
    value = "nginx"
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
    value = "letsencrypt"
  }
  set {
    name  = "server.ingress.tls[0].hosts[0]"
    value = "argocd.adrianmagarola.click"
  }
  set {
    name  = "server.ingress.tls[0].secretName"
    value = "argocd-tls"
  }
  set {
    name  = "server.extraArgs"
    value = "{--insecure}"
  }
}
###############################################################################
# Letsencrypt issuer
###############################################################################
resource "helm_release" "letsencrypt_issuer" {
  name             = "letsencrypt-issuer"
  namespace        = "cert-manager"
  create_namespace = false
  chart            = "${path.module}/charts/letsencrypt-issuer"

  depends_on = [
    helm_release.cert_manager,
    helm_release.nginx_ingress
  ]
}
###############################################################################
# Nginx Ingress Controller (nginx-stable/nginx-ingress) en namespace "ingress-nginx"
###############################################################################
resource "helm_release" "nginx_ingress" {
  depends_on       = [null_resource.update_helm_cache]
  name             = "nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  version          = "4.12.1" # (o la última estable que quieras)

  values = [
    yamlencode({
      controller = {
        service = {
          type = "NodePort"
          nodePorts = {
            http  = 30080
            https = 30443
          }
        }
        nodeSelector = {
          "node-role.k3s.io/master" = "true"
        }
        ingressClassResource = {
          name            = "nginx"
          controllerValue = "k8s.io/ingress-nginx"
        }
        ingressClassByName = true
        admissionWebhooks = {
          enabled = false
          patch = {
            enabled = false
          }
        }
      }
    })
  ]
}
