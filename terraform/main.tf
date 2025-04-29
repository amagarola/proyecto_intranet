# Genera una clave privada RSA para usarla en la conexión SSH

module "k3s_cluster" {
  source            = "./modules/k3s-cluster"
  security_group_id = aws_security_group.k3s_sg.id
}

module "helm_releases" {
  source     = "./modules/helm-releases"
  depends_on = [module.k3s_cluster]
}

module "proxy" {
  source = "./modules/proxy"

  ami_id        = "ami-0e449927258d45bc4"
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  vpc_id        = var.vpc_id
  domains       = var.domains
  name          = "ec2-proxy"
  target_ip     = module.k3s_cluster.master_private_ip
}
