variable "worker_count" {
  description = "Number of worker nodes to create"
  type        = number
  default     = 1
}

variable "aws_key_name" {
  default = "k3s-key" # Asegúrate de que este nombre coincide con el de AWS
}

variable "private_key_path" {
  description = "Path to private key file for SSH connections"
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
  description = "AMI ID for EC2 instances"
  default     = "ami-084568db4383264d4"
}
variable "security_group_id" {
  description = "Security group ID to attach to instances"
  type        = string
}
