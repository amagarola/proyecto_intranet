##########################
# Buscar Hosted Zone existente
##########################

data "aws_route53_zone" "main" {
  name = "adrianmagarola.click."
}

# data "kubernetes_service" "traefik_lb" {
#   metadata {
#     name      = "traefik"
#     namespace = "kube-system"
#   }
# }
##########################
# Crear registro raíz (dominio principal)
##########################

resource "aws_route53_record" "root" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domains[0]
  type    = "A"
  ttl     = 60
  records = [module.proxy.proxy_public_ip]
}

##########################
# Crear subdominio para ArgoCD
##########################

resource "aws_route53_record" "argocd" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domains[1]
  type    = "A"
  ttl     = 60
  records = [module.proxy.proxy_public_ip]
}

# resource "aws_route53_record" "proxy_domains" {
#   for_each = toset(var.domains)

#   zone_id = var.zone_id
#   name    = each.value
#   type    = "A"
#   ttl     = 60
#   records = [module.proxy.proxy_public_ip]
# }
resource "null_resource" "extract_tls_cert" {
  depends_on = [module.helm_releases]

  provisioner "local-exec" {
    command = <<EOT
  ssh -i modules/k3s-cluster/k3s-key.pem -o StrictHostKeyChecking=no ubuntu@${module.k3s_cluster.master_public_ip} <<EOF
  set -euxo pipefail

  # Extraer el certificado TLS de cert-manager
  kubectl get secret argocd-tls -n argocd -o jsonpath='{.data.tls\\.crt}' | base64 -d > /tmp/argocd.crt
  kubectl get secret argocd-tls -n argocd -o jsonpath='{.data.tls\\.key}' | base64 -d > /tmp/argocd.key

  chmod 600 /tmp/argocd.*
EOF
EOT
  }
}
