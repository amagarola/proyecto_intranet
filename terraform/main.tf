# Genera una clave privada RSA para usarla en la conexión SSH
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

# Configura un grupo de seguridad para las instancias de k3s
resource "aws_security_group" "k3s_sg" {
  name        = "k3s-sg"
  description = "Traffic for k3s cluster (SSH, API, Ingress)"

  #######################################################
  # INGRESS
  #######################################################

  # 1 ─ SSH (gestionar las instancias)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ← cambia a tu IP 1.2.3.4/32 si quieres limitarlo
  }

  # 2 ─ API-server k3s
  ingress {
    description = "kubernetes API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # o solo tu oficina/VPN
  }

  # 3 ─ Ingress-nginx expuesto como NodePort 30080 / 30443
  #     (si cambiaste los puertos en Helm)
  ingress {
    description = "Ingress HTTP (NodePort 30080)"
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Ingress HTTPS (NodePort 30443)"
    from_port   = 30443
    to_port     = 30443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ── Si en vez de NodePort usas hostPort 80/443 o MetalLB/LoadBalancer,
  #    elimina las reglas 3 y 4 y crea las que correspondan (80/443).

  #######################################################
  # EGRESS  (todo permitido para que los nodos salgan a Internet)
  #######################################################
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Crea la instancia maestra (master) de k3s
resource "aws_instance" "master" {
  ami             = "ami-084568db4383264d4" # Imagen de Ubuntu para la instancia master
  instance_type   = "t3.small"
  key_name        = aws_key_pair.k3s.key_name
  security_groups = [aws_security_group.k3s_sg.name]
  tags            = { Name = "node-master" }

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
      "sudo k3s-uninstall.sh   || true",
      "sudo rm -rf /var/lib/rancher/k3s /etc/rancher/k3s",

      # ------------------------------------------------------------------
      # 4) Crear config.yaml con la SAN = IP pública
      # ------------------------------------------------------------------
      "sudo tee /etc/rancher/k3s/config.yaml >/dev/null <<EOF\nwrite-kubeconfig-mode: \"644\"\ntls-san:\n  - ${self.public_ip}\n  - 127.0.0.1\nEOF",

      # ------------------------------------------------------------------
      # 5) Instalar k3s **con la SAN** explícita
      # ------------------------------------------------------------------
      "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='server --tls-san ${self.public_ip}' sh -",

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

      # (opcional) quitar certificados/client-key si solo quieres usar token
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path) # Ruta a la clave privada SSH
      host        = self.public_ip
    }

    on_failure = fail # Si falla, no continúa el proceso
  }

}

# Crea las instancias worker de k3s
resource "aws_instance" "workers" {
  depends_on      = [aws_instance.master]
  count           = var.worker_count        # Número de instancias worker
  ami             = "ami-084568db4383264d4" # Imagen de Ubuntu para los workers
  instance_type   = "t3.small"
  key_name        = aws_key_pair.k3s.key_name
  security_groups = [aws_security_group.k3s_sg.name]
  tags            = { Name = "node-worker-${count.index}" }

  # Transfiere la clave privada al worker
  provisioner "file" {
    source      = "${path.module}/k3s-key.pem"
    destination = "/home/ubuntu/.ssh/k3s-key.pem"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path) # Ruta a la clave privada SSH
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
      private_key = file(var.private_key_path)
      host        = self.public_ip
      timeout     = "5m"
    }
  }
}
