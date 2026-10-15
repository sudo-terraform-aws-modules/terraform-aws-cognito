output "user_pool_id" {
  description = "ID of the user pool"
  value       = module.cognito.user_pool_id
}

output "user_pool_issuer_url" {
  description = "OIDC issuer URL of the user pool"
  value       = module.cognito.user_pool_issuer_url
}

output "domain_url" {
  description = "Base URL of the managed login and OAuth endpoints"
  value       = module.cognito.domain_url
}

output "client_ids" {
  description = "App client IDs keyed by client name"
  value       = module.cognito.client_ids
}

output "client_secrets" {
  description = "App client secrets keyed by client name"
  value       = module.cognito.client_secrets
  sensitive   = true
}

output "resource_server_scope_identifiers" {
  description = "Fully qualified scope names keyed by resource server identifier"
  value       = module.cognito.resource_server_scope_identifiers
}

output "identity_pool_id" {
  description = "ID of the identity pool"
  value       = module.cognito.identity_pool_id
}
