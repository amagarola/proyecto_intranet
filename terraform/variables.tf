variable "domains" {
  type        = list(string)
  description = "Lista de dominios"
  default = [
    "adrianmagarola.click",
    "argocd.adrianmagarola.click",
    "wikijs.adrianmagarola.click",
    "grafana.adrianmagarola.click",
    "auth.adrianmagarola.click",
  ]
}

variable "ami_id" {
  type        = string
  description = "AMI ID para la instancia EC2"
  default     = "ami-084568db4383264d4"
}

variable "instance_type" {
  description = "Tipo de instancia para el proxy"
  type        = string
  default     = "t2.micro"
}

# variable "key_name" {
#   description = "Nombre de la clave SSH para acceder a las instancias"
#   type        = string
# }

variable "subnet_id" {
  description = "ID de la subred donde se desplegará el proxy"
  type        = string
  default     = "subnet-04a08c25e59902a54"
}

variable "vpc_id" {
  description = "ID de la VPC donde se desplegará el proxy"
  type        = string
  default     = "vpc-0d936a508e10d78d8"
}

variable "zone_id" {
  description = "ID de la zona de Route 53 donde se gestionan los dominios"
  type        = string
  default     = "Z00983232VK8B1OALGWO1"
}
variable "k3s_master_ip" {
  type    = string
  default = ""
}
variable "github_token" {
  description = "Token personal de GitHub para autenticación OAuth o API"
  type        = string
  sensitive   = true
}

variable "github_client_id" {
  description = "GitHub OAuth App Client ID"
  type        = string
}

variable "github_client_secret" {
  description = "GitHub OAuth App Client Secret"
  type        = string
  sensitive   = true
}

variable "target_port_http" {
  description = "Target HTTP port for the proxy to forward to (e.g., k3s ingress NodePort)"
  type        = number
  default     = 30080
}

variable "target_port_https" {
  description = "Target HTTPS port for the proxy to forward to (e.g., k3s ingress NodePort)"
  type        = number
  default     = 30443
}

variable "master_private_ip" {
  description = "Private IP address of the K3s master node"
  type        = string
  default     = ""
}

variable "proxy_public_ip" {
  description = "Public IP address of the proxy node"
  type        = string
  default     = ""
}

variable "aws_access_key" {
  description = "Clave de acceso AWS (Access Key ID)"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "Clave secreta de AWS (Secret Access Key)"
  type        = string
  sensitive   = true
}

variable "cookie_secret" {
  description = "Cookie Secret para OAuth2 Proxy"
  type        = string
  sensitive   = true
}
