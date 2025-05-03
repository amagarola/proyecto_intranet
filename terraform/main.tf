# Genera una clave privada RSA para usarla en la conexión SSH

module "k3s_cluster" {
  source               = "./modules/k3s-cluster"
  security_group_id    = aws_security_group.k3s_sg.id
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_profile.name
}

module "helm_releases" {
  source        = "./modules/helm-releases"
  depends_on    = [module.k3s_cluster]
  k3s_master_ip = module.k3s_cluster.master_public_ip
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

resource "null_resource" "extract_tls_cert" {
  provisioner "local-exec" {
    command = <<EOT
    cat << 'EOF' > ./my_ssh_config
Host k3s
  HostName ${module.k3s_cluster.master_public_ip}
  User ubuntu
  IdentityFile /modules/k3s-cluster/k3s-key.pem
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null

Host proxy
  HostName ${module.proxy.public_ip}
  User ubuntu
  IdentityFile /modules/proxy/ec2-proxy-key.pem
  ProxyJump k3s
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
EOF
  ssh -i modules/k3s-cluster/k3s-key.pem -o StrictHostKeyChecking=no ubuntu@${module.k3s_cluster.master_public_ip} <<'EOF'
  set -euxo pipefail

  sudo apt-get install -y jq

  export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
  echo "🔍 Esperando certificado TLS válido para ArgoCD..."

  START=$(date +%s)
  while true; do
    SECRET_NAME=$(kubectl get secret -n argocd -o json | jq -r '.items[] | select(.metadata.name | startswith("argocd-tls")) | .metadata.name' | head -n1 || true)
    if [ -n "$SECRET_NAME" ]; then
      STATUS=$(kubectl get certificate argocd-tls -n argocd -o json | jq -r '.status.conditions[]? | select(.type=="Ready") | .status' || true)
      if [ "$STATUS" = "True" ]; then
        echo "✅ Certificado $SECRET_NAME está listo."
        break
      fi
      echo "⏳ Certificado encontrado pero aún no está listo. Esperando..."
    else
      echo "🔍 Buscando secret TLS que comience con 'argocd-tls'..."
    fi

    NOW=$(date +%s)
    ELAPSED=$((NOW - START))
    if [ "$ELAPSED" -ge 600 ]; then
      echo "❌ Timeout de 5 minutos esperando que el certificado esté listo"
      exit 1
    fi
    sleep 30
  done

  # Exportar certificados
  kubectl get secret "$SECRET_NAME" -n argocd -o jsonpath='{.data.tls\.crt}' | base64 -d > /tmp/argocd.crt
  kubectl get secret "$SECRET_NAME" -n argocd -o jsonpath='{.data.tls\.key}' | base64 -d > /tmp/argocd.key
  chmod 600 /tmp/argocd.*
EOF

ssh -i modules/k3s-cluster/k3s-key.pem -o StrictHostKeyChecking=no ubuntu@<OTRA_IP>
EOT
  }
  depends_on = [module.helm_releases.argocd]
}
# resource "null_resource" "generate_script" {
#   provisioner "local-exec" {
#     command = <<EOT
# cat << 'EOF' > setup.sh
# #!/bin/bash
# echo "Este es un script generado por Terraform"
# chmod 600 /tmp/argocd.*
# ssh -i modules/k3s-cluster/k3s-key.pem ubuntu@<OTRA_IP>





# scp -i /root/k3s-key.pem -o StrictHostKeyChecking=no ubuntu@${var.target_ip}:/tmp/argocd.crt /etc/nginx/certs/argocd.crt || true
# scp -i /root/k3s-key.pem -o StrictHostKeyChecking=no ubuntu@${var.target_ip}:/tmp/argocd.key /etc/nginx/certs/argocd.key || true
# chmod 600 /etc/nginx/certs/argocd.*

# 7. Reiniciar NGINX si los certificados fueron copiados
# if [ -s /etc/nginx/certs/argocd.crt ] && [ -s /etc/nginx/certs/argocd.key ]; then
#     echo "✅ Certificados reales detectados, reiniciando NGINX con SSL válido"
#     systemctl restart nginx
# else
#     echo "⚠️ Certificados reales no encontrados, continúas con autofirmado"
# fi



# scp -i /root/k3s-key.pem -o StrictHostKeyChecking=no ubuntu@44.199.247.204:/tmp/argocd.crt /etc/nginx/certs/argocd.crt || true
# scp -i /root/k3s-key.pem -o StrictHostKeyChecking=no ubuntu@44.199.247.204:/tmp/argocd.key /etc/nginx/certs/argocd.key || true
# EOF
# chmod +x setup.sh

# kubectl --kubeconfig=.\k3s-ec2.yaml get nodes
# kubectl --kubeconfig=.\modules/k3s-cluster/k3s.yaml get nodes
# EOT
#   }
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
