variable "k3s_master_ip" {
  description = "The master public IP of the k3s cluster"
  type        = string
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
