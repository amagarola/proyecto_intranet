resource "tls_private_key" "ec2-proxy" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2-proxy" {
  key_name   = "ec2-proxy-key"
  public_key = tls_private_key.ec2-proxy.public_key_openssh
}

resource "local_file" "ec2-proxy_private_key" {
  filename        = "${path.module}/ec2-proxy-key.pem"
  content         = tls_private_key.ec2-proxy.private_key_pem
  file_permission = "0400" # Permiso para que SSH lo acepte
}

resource "aws_instance" "ec2-proxy" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  iam_instance_profile        = var.iam_instance_profile
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  key_name                    = aws_key_pair.ec2-proxy.key_name
  associate_public_ip_address = false

  tags = {
    Name = var.name
  }

  user_data = <<-EOF
#!/bin/bash
set -euxo pipefail

dnf update -y || true
dnf install -y nginx openssl

systemctl enable nginx
systemctl start nginx

mkdir -p /etc/nginx/sites-available/
mkdir -p /etc/nginx/sites-enabled/
mkdir -p /etc/nginx/certs/

# 1. Generar certificados autofirmados iniciales
openssl req -x509 -nodes -days 3 -newkey rsa:2048 \
  -keyout /etc/nginx/certs/adrianmagarola.key \
  -out /etc/nginx/certs/adrianmagarola.crt \
  -subj "/CN=${var.domains[0]}"

chmod 600 /etc/nginx/certs/adrianmagarola.*

# 2. Insertar include en nginx.conf si falta
grep -q "sites-enabled" /etc/nginx/nginx.conf || \
  sed -i '/http {/a \    include /etc/nginx/sites-enabled/*;' /etc/nginx/nginx.conf

# 3. Crear configuración de NGINX con autofirmado
cat <<EOT > /etc/nginx/sites-available/default
server {
    listen 80;
    server_name ${join(" ", var.domains)};

    location / {
        proxy_pass http://${var.target_ip}:${var.target_port_http};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}

server {
    listen 443 ssl;
    server_name ${join(" ", [var.domains[0], var.domains[2], var.domains[3], var.domains[4]])};

    ssl_certificate /etc/nginx/certs/adrianmagarola.crt;
    ssl_certificate_key /etc/nginx/certs/adrianmagarola.key;

    location / {
        proxy_pass https://${var.target_ip}:${var.target_port_https};
        proxy_ssl_verify off;
        proxy_ssl_session_reuse off;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}

server {
    listen 443 ssl;
    server_name ${var.domains[1]};

    ssl_certificate /etc/nginx/certs/adrianmagarola.crt;
    ssl_certificate_key /etc/nginx/certs/adrianmagarola.key;

    location / {
        proxy_pass https://${var.target_ip}:${var.target_port_https};
        proxy_ssl_verify off;
        proxy_ssl_session_reuse off;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOT

ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default || true
systemctl reload nginx
EOF
}

resource "aws_security_group" "this" {
  name        = "${var.name}-sg"
  description = "Allow HTTP and HTTPS"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
