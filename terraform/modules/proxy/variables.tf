variable "ami_id" {
  type        = string
  description = "ID de la AMI para la instancia EC2"
}

variable "instance_type" {
  type        = string
  description = "Tipo de instancia EC2"
}

variable "subnet_id" {
  type        = string
  description = "ID de la subred donde lanzar la instancia"
}

variable "vpc_id" {
  type        = string
  description = "ID del VPC para la seguridad de la instancia"
}

variable "key_name" {
  type        = string
  description = "Nombre del key pair para acceder por SSH"
  default     = "ec2-proxy-key"
}

variable "name" {
  type        = string
  description = "Nombre para la instancia EC2 y su Security Group"
}

variable "target_ip" {
  type        = string
  description = "Dirección IP interna de destino"
  default     = "172.31.11.86" # IP de la instancia de nginx o nginx
}

variable "target_port_http" {
  type        = number
  description = "Puerto HTTP de destino interno"
  default     = 30080
}

variable "target_port_https" {
  type        = number
  description = "Puerto HTTPS de destino interno"
  default     = 30443
}
variable "domains" {
  type        = list(string)
  description = "Lista de dominios"
  default = [
    "adrianmagarola.click",
    "argocd.adrianmagarola.click"
  ]
}
variable "aws_key_name" {
  default = "ec2-proxy-key"
}
variable "k3s_private_key_pem" {
  type        = string
  description = "K3s master private key for SSH access"
}
variable "private_key_path" {
  description = "Ruta al archivo de clave privada para conexiones SSH"
  type        = string
  default     = "ec2-proxy-key.pem"
}
