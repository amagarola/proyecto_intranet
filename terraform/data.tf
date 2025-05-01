data "external" "kubeconfig" {
  depends_on = [module.k3s_cluster]

  program = [
    "sh", "-c",
    <<-EOT
    ssh -o StrictHostKeyChecking=no -i modules/k3s-cluster/k3s-key.pem ubuntu@${module.k3s_cluster.master_public_ip} '
      yaml=/etc/rancher/k3s/k3s.yaml
      CA=$(grep certificate-authority-data "$yaml" | sed "s/.*: //")
      CERT=$(grep client-certificate-data "$yaml" | sed "s/.*: //")
      KEY=$(grep client-key-data "$yaml" | sed "s/.*: //")
      echo "{\"ca\":\"$CA\",\"cert\":\"$CERT\",\"key\":\"$KEY\"}"
    '
    EOT
  ]
}
