
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
  ami                         = "ami-0e449927258d45bc4" # Amazon Linux 2
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  key_name                    = aws_key_pair.ec2-proxy.key_name
  associate_public_ip_address = true

  tags = {
    Name = var.name
  }

  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  dnf update -y
  dnf install -y nginx

  systemctl enable nginx
  systemctl start nginx

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
      server_name ${join(" ", var.domains)};

      ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
      ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;

      location / {
          proxy_pass https://${var.target_ip}:${var.target_port_https};
          proxy_set_header Host \$host;
          proxy_set_header X-Real-IP \$remote_addr;
      }
  }
  EOT
  
  mkdir -p /etc/ssl/certs /etc/ssl/private

  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/ssl-cert-snakeoil.key \
    -out /etc/ssl/certs/ssl-cert-snakeoil.pem \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=Org/CN=localhost"

  systemctl restart nginx
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
