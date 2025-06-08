resource "aws_security_group" "k3s_sg" {
  name        = "k3s-sg"
  description = "Traffic for k3s cluster (SSH, API, Ingress)"

  #######################################################
  # INGRESS
  #######################################################

  # Permitir todo el tráfico entrante
  ingress {
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

# --- BLOQUE RESTRINGIDO POR IP PÚBLICA (comentado para futura implementación) ---
# data "http" "myip" {
#   url = "https://ifconfig.me/ip"
# }
#
# resource "aws_security_group" "k3s_sg" {
#   name        = "k3s-sg"
#   description = "Traffic for k3s cluster (SSH, API, Ingress)"
#
#   #######################################################
#   # INGRESS
#   #######################################################
#
#   ingress {
#     description = "SSH"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["${trimspace(data.http.myip.response_body)}/32"]
#   }
#   ingress {
#     description = "kubernetes API"
#     from_port   = 6443
#     to_port     = 6443
#     protocol    = "tcp"
#     cidr_blocks = ["${trimspace(data.http.myip.response_body)}/32"]
#   }
#   ingress {
#     description = "Ingress HTTP (NodePort 30080)"
#     from_port   = 30080
#     to_port     = 30080
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     description = "Ingress HTTPS (NodePort 30443)"
#     from_port   = 30443
#     to_port     = 30443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     description = "ArgoCD HTTP"
#     from_port   = 30081
#     to_port     = 30081
#     protocol    = "tcp"
#     cidr_blocks = ["${trimspace(data.http.myip.response_body)}/32"]
#   }
#
#   #######################################################
#   # EGRESS  (todo permitido para que los nodos salgan a Internet)
#   #######################################################
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }
# -----------------------------------------------------------------------------
