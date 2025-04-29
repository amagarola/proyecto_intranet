variable "worker_count" {
  description = "Número de nodos worker a crear"
  type        = number
  default     = 1
}

variable "aws_key_name" {
  default = "k3s-key"
}

variable "private_key_path" {
  description = "Ruta al archivo de clave privada para conexiones SSH"
  type        = string
  default     = "k3s-key.pem"
}

variable "instance_type" {
  description = "Tipo de instancia EC2 para los nodos"
  type        = string
  default     = "t3.small"
}

variable "ami_id" {
  type        = string
  description = "ID de la AMI para las instancias EC2"
  default     = "ami-084568db4383264d4"
}

variable "security_group_id" {
  description = "ID del grupo de seguridad a adjuntar a las instancias"
  type        = string
  default     = ""
}
