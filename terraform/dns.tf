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
  records = [module.k3s_cluster.master_public_ip]
}

##########################
# Crear subdominio para ArgoCD
##########################

resource "aws_route53_record" "argocd" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "argocd.${var.domains[1]}"
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
