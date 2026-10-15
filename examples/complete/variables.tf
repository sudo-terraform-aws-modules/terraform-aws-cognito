variable "region" {
  description = "Region to deploy the example in"
  type        = string
  default     = "eu-west-1"
}

variable "entra_tenant_id" {
  description = "Microsoft Entra ID tenant ID"
  type        = string
}

variable "entra_client_id" {
  description = "Client ID of the Entra ID app registration"
  type        = string
}

variable "entra_client_secret" {
  description = "Client secret of the Entra ID app registration"
  type        = string
  sensitive   = true
}
