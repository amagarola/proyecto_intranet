##########################
# Buscar Hosted Zone existente
##########################

data "aws_route53_zone" "main" {
  name = "adrianmagarola.click."
}

##########################
# Crear subdominio para ArgoCD
##########################

resource "aws_route53_record" "domains" {
  for_each = toset(var.domains)
  zone_id  = data.aws_route53_zone.main.zone_id
  name     = each.key
  type     = "A"
  ttl      = 60
  records  = [module.proxy.proxy_public_ip]
}

##########################
# Crear registro para K3s Master
##########################

resource "aws_route53_record" "k3s_master" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "k3s.adrianmagarola.click"
  type    = "A"
  ttl     = 60
  records = [module.k3s_cluster.master_public_ip]
}
