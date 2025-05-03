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
