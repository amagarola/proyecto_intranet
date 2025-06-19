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
variable "instance_type_master" {
  description = "Tipo de instancia EC2 para los nodos"
  type        = string
  default     = "t3.medium"
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

variable "iam_instance_profile" {
  type        = string
  description = "IAM instance profile name for EC2 (for SSM access)"
}

variable "worker_min_size" {
  description = "Número mínimo de nodos worker en el ASG"
  type        = number
  default     = 1
}

variable "worker_max_size" {
  description = "Número máximo de nodos worker en el ASG"
  type        = number
  default     = 3
}

variable "worker_desired_capacity" {
  description = "Capacidad deseada de nodos worker en el ASG"
  type        = number
  default     = 1
}

variable "subnet_ids" {
  description = "Lista de subnets para el Auto Scaling Group"
  type        = list(string)
}
