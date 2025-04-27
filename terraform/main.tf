# Genera una clave privada RSA para usarla en la conexión SSH

module "k3s_cluster" {
  source            = "./modules/k3s-cluster"
  security_group_id = aws_security_group.k3s_sg.id
}

module "helm_releases" {
  source     = "./modules/helm-releases"
  depends_on = [module.k3s_cluster]
}

