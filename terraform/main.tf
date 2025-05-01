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
  depends_on           = [null_resource.extract_tls_cert]
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
  depends_on = [module.helm_releases]

  provisioner "local-exec" {
    command = <<EOT
  ssh -i modules/k3s-cluster/k3s-key.pem -o StrictHostKeyChecking=no ubuntu@${module.k3s_cluster.master_public_ip} <<EOF
  set -euxo pipefail
  apt-get install -y jq

  # Buscar el nombre real del Secret TLS que empiece por "argocd-tls"
  SECRET_NAME=$(kubectl get secret -n argocd -o json | jq -r '.items[] | select(.metadata.name | startswith("argocd-tls")) | .metadata.name' | head -n1)

  if [ -z "$SECRET_NAME" ]; then
    echo "❌ No se encontró ningún Secret TLS que empiece con 'argocd-tls' en el namespace 'argocd'"
    exit 1
  fi

  echo "✅ Usando secret: $SECRET_NAME"

  # Extraer los certificados
  kubectl get secret "$SECRET_NAME" -n argocd -o jsonpath='{.data.tls\.crt}' | base64 -d > /tmp/argocd.crt
  kubectl get secret "$SECRET_NAME" -n argocd -o jsonpath='{.data.tls\.key}' | base64 -d > /tmp/argocd.key

  chmod 600 /tmp/argocd.*


  chmod 600 /tmp/argocd.*
EOF
EOT
  }
}

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
