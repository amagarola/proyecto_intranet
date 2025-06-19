# Crea la instancia maestra (master) de k3s
resource "tls_private_key" "k3s" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Crea una Key Pair en AWS con la clave pública generada
resource "aws_key_pair" "k3s" {
  key_name   = "k3s-key"
  public_key = tls_private_key.k3s.public_key_openssh
}

# Guarda la clave privada en un archivo local (k3s-key.pem) para usarla en la conexión SSH
resource "local_file" "k3s_private_key" {
  filename        = "${path.module}/k3s-key.pem"
  content         = tls_private_key.k3s.private_key_pem
  file_permission = "0400" # Permiso para que SSH lo acepte
}
resource "aws_instance" "master" {
  ami                    = var.ami_id
  instance_type          = "vaer.instance_type_master"
  key_name               = aws_key_pair.k3s.key_name
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.iam_instance_profile
  tags = {
    Name                             = "k3s-master"
    "kubernetes.io/cluster/k3s"      = "owned"
    "node-role.kubernetes.io/master" = "true"
  }

  provisioner "remote-exec" {
    inline = [
      "set -x", # Add this line for verbose output
      # ------------------------------------------------------------------
      # 1) Actualizar paquetes y utilidades básicas
      # ------------------------------------------------------------------
      "sudo apt-get update -y",
      "sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common",

      # ------------------------------------------------------------------
      # 2) Instalar kubectl (última estable)
      # ------------------------------------------------------------------
      "curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl",
      "chmod +x ./kubectl && sudo mv ./kubectl /usr/local/bin/kubectl",

      # ------------------------------------------------------------------
      # 3) **Limpiar instalación anterior de k3s y sus certificados**
      # ------------------------------------------------------------------
      "sudo systemctl stop k3s || true",
      "sudo /usr/local/bin/k3s-uninstall.sh || true",
      "sudo rm -rf /var/lib/rancher/k3s /etc/rancher/k3s",

      # ------------------------------------------------------------------
      # 4) Crear config.yaml con la SAN = IP pública
      # ------------------------------------------------------------------
      "sudo mkdir -p /etc/rancher/k3s/",
      "echo \"write-kubeconfig-mode: \\\"0644\\\"\" | sudo tee /etc/rancher/k3s/config.yaml",
      "echo \"tls-san:\" | sudo tee -a /etc/rancher/k3s/config.yaml",
      "echo \"  - k3s.adrianmagarola.click\" | sudo tee -a /etc/rancher/k3s/config.yaml",
      "echo \"node-label:\" | sudo tee -a /etc/rancher/k3s/config.yaml",
      "echo \"  - \\\"node-role.k3s.io/master=true\\\"\" | sudo tee -a /etc/rancher/k3s/config.yaml",
      # "echo \"disable-cloud-controller: true\" | sudo tee -a /etc/rancher/k3s/config.yaml",

      # ------------------------------------------------------------------
      # 5) Instalar k3s **con la SAN** explícita
      # ------------------------------------------------------------------
      "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='server --disable traefik --tls-san ${self.public_ip}' sh -",

      # ------------------------------------------------------------------
      # 6) Esperar a que el API-server esté listo
      # ------------------------------------------------------------------
      "echo '⏳ Esperando a que el API responda…'",
      "for i in {1..30}; do sudo kubectl get --raw=/version >/dev/null 2>&1 && break || sleep 4; done",



      "kubectl delete helmchart traefik -n kube-system || true",
      "kubectl delete svc,deploy -l app.kubernetes.io/name=traefik -n kube-system || true",


      # ------------------------------------------------------------------
      # 7) Forzar que el kubeconfig generado apunte a la IP pública
      # ------------------------------------------------------------------
      "sudo kubectl config set-cluster default --server=https://${self.public_ip}:6443 --kubeconfig=/etc/rancher/k3s/k3s.yaml",

      # Copiar kubeconfig y exportarlo
      "mkdir -p /home/ubuntu/.kube",
      "sudo cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config",
      "sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config",
      "echo 'export KUBECONFIG=$HOME/.kube/config' >> /home/ubuntu/.bashrc",


      # ────────────────────────────────────────────────────────────
      # A) Ajustar el kubeconfig para que use la IP pública
      # ────────────────────────────────────────────────────────────
      "sudo kubectl config set-cluster default --server=https://${self.public_ip}:6443 --kubeconfig=/etc/rancher/k3s/k3s.yaml",

      # B) Copiarlo al home y dar permisos a ubuntu
      "mkdir -p /home/ubuntu/.kube",
      "sudo cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config",
      "sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config",
      "alias k='kubectl'",

      # ------------------------------------------------------------------
      # Instalar Helm y configurar repositorios
      # ------------------------------------------------------------------
      "curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash",
      "helm repo add jetstack https://charts.jetstack.io",
      "helm repo add argo https://argoproj.github.io/argo-helm",
      "helm repo add nginx-stable https://kubernetes.github.io/ingress-nginx",
      "helm repo update",

      # ------------------------------------------------------------------
      # Desplegar cert-manager
      # ------------------------------------------------------------------
      "helm upgrade --install cert-manager jetstack/cert-manager \\",
      "  --namespace cert-manager \\",
      "  --create-namespace \\",
      "  --version v1.13.2 \\",
      "  --set installCRDs=true \\",
      "  --set startupapicheck.enabled=false",

      # ------------------------------------------------------------------
      # Desplegar nginx-ingress
      # ------------------------------------------------------------------
      # "helm upgrade --install nginx nginx-stable/ingress-nginx \\",
      # "  --namespace ingress-nginx \\",
      # "  --create-namespace \\",
      # "  --version 4.12.1 \\",
      # "  --set controller.service.type=NodePort \\",
      # "  --set controller.service.nodePorts.http=30080 \\",
      # "  --set controller.service.nodePorts.https=30443 \\",
      # "  --set controller.nodeSelector.node-role.k3s.io/master=\"true\" \\",
      # "  --set controller.ingressClassResource.name=nginx \\",
      # "  --set controller.ingressClassResource.controllerValue=k8s.io/ingress-nginx \\",
      # "  --set controller.ingressClassByName=true \\",
      # "  --set controller.admissionWebhooks.enabled=false \\",
      # "  --set controller.admissionWebhooks.patch.enabled=false"

      # ------------------------------------------------------------------
      # Desplegar letsencrypt-issuer
      # ------------------------------------------------------------------
      # "helm upgrade --install letsencrypt-issuer ../charts/letsencrypt-issuer \\",
      # "  --namespace cert-manager \\",
      # "  --create-namespace \\",
      # "  --set email=adrianmagarola@gmail.com \\",
      # "  --set ingressClass=nginx",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.k3s.private_key_pem
      host        = self.public_ip
    }

    on_failure = fail # Si falla, no continúa el proceso
  }

}

# --- AUTOSCALING GROUP PARA WORKERS ---

resource "aws_launch_template" "worker" {
  name_prefix   = "k3s-worker-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.k3s.key_name
  iam_instance_profile {
    name = var.iam_instance_profile
  }
  vpc_security_group_ids = [var.security_group_id]
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "node-worker"
    }
  }
  user_data = base64encode(templatefile("${path.module}/user_data_worker.sh.tftpl", {
    master_private_ip   = aws_instance.master.private_ip,
    master_public_ip    = aws_instance.master.public_ip,
    k3s_private_key_pem = tls_private_key.k3s.private_key_pem,
    worker_label        = "node-role.kubernetes.io/worker=true",
    worker_role         = "worker" # Añadido para uso en el script
  }))
}

resource "aws_autoscaling_group" "workers" {
  name                = "k3s-workers-asg"
  min_size            = var.worker_min_size
  max_size            = var.worker_max_size
  desired_capacity    = var.worker_desired_capacity
  vpc_zone_identifier = var.subnet_ids
  launch_template {
    id      = aws_launch_template.worker.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "node-worker"
    propagate_at_launch = true
  }
  tag {
    key                 = "kubernetes.io/role/worker"
    value               = "1"
    propagate_at_launch = true
  }
  tag {
    key                 = "node-role.kubernetes.io/worker"
    value               = "true"
    propagate_at_launch = true
  }
  tag {
    key                 = "kubernetes.io/cluster/k3s"
    value               = "owned"
    propagate_at_launch = true
  }
  depends_on = [aws_instance.master]
}

resource "aws_autoscaling_policy" "scale_out" {
  name                   = "k3s-workers-scale-out"
  autoscaling_group_name = aws_autoscaling_group.workers.name
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "k3s-workers-scale-in"
  autoscaling_group_name = aws_autoscaling_group.workers.name
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "k3s-workers-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 120
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "This metric triggers a scale out when memory > 70%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.workers.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_out.arn]
}

resource "aws_cloudwatch_metric_alarm" "memory_low" {
  alarm_name          = "k3s-workers-memory-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 120
  statistic           = "Average"
  threshold           = 30
  alarm_description   = "This metric triggers a scale in when memory < 30%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.workers.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_in.arn]
}

