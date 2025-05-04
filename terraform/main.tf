module "k3s_cluster" {
  source               = "./modules/k3s-cluster"
  security_group_id    = aws_security_group.k3s_sg.id
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_profile.name
}

module "helm_releases" {
  source        = "./modules/helm-releases"
  depends_on    = [module.k3s_cluster]
  k3s_master_ip = module.k3s_cluster.master_public_ip

  # Pasar las variables de GitHub al módulo
  github_client_id     = var.github_client_id
  github_client_secret = var.github_client_secret
  github_token         = var.github_token

}

module "proxy" {
  source               = "./modules/proxy"
  depends_on           = [module.helm_releases.argocd]
  ami_id               = "ami-0e449927258d45bc4"
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  vpc_id               = var.vpc_id
  domains              = var.domains
  name                 = "ec2-proxy"
  target_ip            = module.k3s_cluster.master_private_ip
  k3s_private_key_pem  = module.k3s_cluster.private_key_pem
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_profile.name
}

# resource "null_resource" "extract_tls_cert" {
#   provisioner "remote-exec" {
#     inline = [
#       <<-EOT
#         #!/bin/bash
#         ssh -F ./my_ssh_config k3s <<'EOF'
#         set -euxo pipefail

#         sudo apt-get install -y jq

#         export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
#         echo "🔍 Esperando certificado TLS válido para ArgoCD..."

#         START=$(date +%s)
#         while true; do
#           SECRET_NAME=$(kubectl get secret -n argocd -o json | jq -r '.items[] | select(.metadata.name | startswith("argocd-tls")) | .metadata.name' | head -n1 || true)
#           if [ -n "$SECRET_NAME" ]; then
#             STATUS=$(kubectl get certificate argocd-tls -n argocd -o json | jq -r '.status.conditions[]? | select(.type=="Ready") | .status' || true)
#             if [ "$STATUS" = "True" ]; then
#               echo "✅ Certificado $SECRET_NAME está listo."
#               break
#             fi
#             echo "⏳ Certificado encontrado pero aún no está listo. Esperando..."
#           else
#             echo "🔍 Buscando secret TLS que comience con 'argocd-tls'..."
#           fi

#           NOW=$(date +%s)
#           ELAPSED=$((NOW - START))
#           if [ "$ELAPSED" -ge 600 ]; then
#             echo "❌ Timeout de 5 minutos esperando que el certificado esté listo"
#             exit 1
#           fi
#           sleep 30
#         done

#         # Exportar certificados
#         kubectl get secret "$SECRET_NAME" -n argocd -o jsonpath='{.data.tls\\.crt}' | base64 -d > /tmp/argocd.crt
#         kubectl get secret "$SECRET_NAME" -n argocd -o jsonpath='{.data.tls\\.key}' | base64 -d > /tmp/argocd.key
#         chmod 600 /tmp/argocd.*
#         EOF
#       EOT,
#       <<-EOT
#         scp -F ./my_ssh_config -o ProxyJump=k3s /tmp/argocd.crt proxy:/etc/nginx/certs/argocd.crt
#         scp -F ./my_ssh_config -o ProxyJump=k3s /tmp/argocd.key proxy:/etc/nginx/certs/argocd.key
#       EOT
#     ]
#   }

#   depends_on = [
#     module.helm_releases
#   ]
# }

resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core_attach" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

