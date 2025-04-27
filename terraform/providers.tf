provider "aws" {
  region = "us-east-1"
}

provider "kubernetes" {
  host                   = "https://${module.k3s_cluster.master_public_ip}:6443"
  client_key             = base64decode(trimspace(data.external.kubeconfig.result["key"]))
  cluster_ca_certificate = base64decode(trimspace(data.external.kubeconfig.result["ca"]))
  client_certificate     = base64decode(trimspace(data.external.kubeconfig.result["cert"]))
}

provider "helm" {
  kubernetes {
    host                   = "https://${module.k3s_cluster.master_public_ip}:6443"
    client_key             = base64decode(trimspace(data.external.kubeconfig.result["key"]))
    cluster_ca_certificate = base64decode(trimspace(data.external.kubeconfig.result["ca"]))
    client_certificate     = base64decode(trimspace(data.external.kubeconfig.result["cert"]))
    #insecure               = true
  }
}
