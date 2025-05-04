provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "kubernetes" {
  host                   = "https://${module.k3s_cluster.master_public_ip}:6443"
  client_key             = base64decode(trimspace(data.external.kubeconfig.result["key"]))
  cluster_ca_certificate = base64decode(trimspace(data.external.kubeconfig.result["ca"]))
  client_certificate     = base64decode(trimspace(data.external.kubeconfig.result["cert"]))
  # config_path            = "${path.module}/modules/k3s-cluster/kubeconfig"
}
locals {
  app_files = fileset("../../apps", "*.yaml")
}

resource "kubernetes_manifest" "applications" {
  for_each = { for f in local.app_files : f => yamldecode(file("../../apps/${f}")) }

  manifest = each.value

  depends_on = [module.helm_releases]
}


provider "helm" {
  kubernetes {
    host                   = "https://${module.k3s_cluster.master_public_ip}:6443"
    client_key             = base64decode(trimspace(data.external.kubeconfig.result["key"]))
    cluster_ca_certificate = base64decode(trimspace(data.external.kubeconfig.result["ca"]))
    client_certificate     = base64decode(trimspace(data.external.kubeconfig.result["cert"]))
  }
}
