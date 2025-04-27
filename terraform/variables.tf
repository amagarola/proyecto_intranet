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
