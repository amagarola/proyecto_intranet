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
  instance_type          = var.instance_type
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
      "echo \"  - ${self.public_ip}\" | sudo tee -a /etc/rancher/k3s/config.yaml",
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


      "curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash",


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

# Crea las instancias worker de k3s
resource "aws_instance" "workers" {
  depends_on             = [aws_instance.master]
  count                  = var.worker_count # Número de instancias worker
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.k3s.key_name
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.iam_instance_profile
  tags                   = { Name = "node-worker-${count.index}" }

  # Transfiere la clave privada al worker
  provisioner "file" {
    source      = "${path.module}/k3s-key.pem"
    destination = "/home/ubuntu/.ssh/k3s-key.pem"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.k3s.private_key_pem
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "chmod 400 /home/ubuntu/.ssh/k3s-key.pem",
      "MASTER_IP=${aws_instance.master.private_ip}",
      "TOKEN=$(ssh -o StrictHostKeyChecking=no -i /home/ubuntu/.ssh/k3s-key.pem ubuntu@${aws_instance.master.public_ip} sudo cat /var/lib/rancher/k3s/server/node-token)",
      "curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$TOKEN sh -",
      "sleep 10",
      "LOCAL_HOSTNAME=$(hostname)",
      "ssh -o StrictHostKeyChecking=no -i /home/ubuntu/.ssh/k3s-key.pem ubuntu@$MASTER_IP \"kubectl label node $LOCAL_HOSTNAME node-role.kubernetes.io/worker=true\""
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.k3s.private_key_pem
      host        = self.public_ip
      timeout     = "5m"
    }
  }
}
# ────────────────────────────────────────────────────────────

