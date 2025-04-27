data "external" "kubeconfig" {
  depends_on = [module.k3s_cluster]

  program = [
    "sh", "-c",
    <<-EOT
  ssh -o StrictHostKeyChecking=no -i modules/k3s-cluster/k3s-key.pem ubuntu@${module.k3s_cluster.master_public_ip} '
    CA=$(sudo cat /etc/rancher/k3s/k3s.yaml | grep certificate-authority-data | awk "{print \\$2}")
    CERT=$(sudo cat /etc/rancher/k3s/k3s.yaml | grep client-certificate-data | awk "{print \\$2}")
    KEY=$(sudo cat /etc/rancher/k3s/k3s.yaml | grep client-key-data | awk "{print \\$2}")
    echo "{\"ca\":\"$CA\",\"cert\":\"$CERT\",\"key\":\"$KEY\"}"
  '
  EOT
  ]

}
