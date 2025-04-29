variable "domains" {
  type        = list(string)
  description = "Lista de dominios"
  default = [
    "adrianmagarola.click",
    "argocd.adrianmagarola.click"
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
  default     = "t3.small"
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
