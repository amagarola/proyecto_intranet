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
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 2 ─ API-server k3s
  ingress {
    description = "kubernetes API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 3 ─ Ingress-nginx expuesto como NodePort 30080 / 30443

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

  ingress {
    description = "ArgoCD HTTP"
    from_port   = 30081
    to_port     = 30081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


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
