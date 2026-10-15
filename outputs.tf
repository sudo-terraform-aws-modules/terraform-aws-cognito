################################################################################
# User pool
################################################################################

output "user_pool_id" {
  description = "ID of the user pool"
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "ARN of the user pool"
  value       = aws_cognito_user_pool.this.arn
}

output "user_pool_name" {
  description = "Name of the user pool"
  value       = aws_cognito_user_pool.this.name
}

output "user_pool_endpoint" {
  description = "Endpoint of the user pool, also the provider name used by identity pools"
  value       = aws_cognito_user_pool.this.endpoint
}

output "user_pool_issuer_url" {
  description = "OIDC issuer URL. Tokens carry this value in the iss claim"
  value       = "https://${aws_cognito_user_pool.this.endpoint}"
}

output "user_pool_jwks_uri" {
  description = "URL of the JSON Web Key Set used to verify token signatures"
  value       = "https://${aws_cognito_user_pool.this.endpoint}/.well-known/jwks.json"
}

################################################################################
# Domain
################################################################################

output "domain" {
  description = "Domain prefix or custom domain of the user pool, or null when not created"
  value       = try(aws_cognito_user_pool_domain.this[0].domain, null)
}

output "domain_url" {
  description = "Base URL of the managed login and OAuth endpoints, or null when no domain is created"
  value = try(
    var.domain_certificate_arn != null
    ? "https://${aws_cognito_user_pool_domain.this[0].domain}"
    : "https://${aws_cognito_user_pool_domain.this[0].domain}.auth.${aws_cognito_user_pool.this.region}.amazoncognito.com",
    null
  )
}

output "domain_cloudfront_distribution" {
  description = "CloudFront distribution to alias a custom domain to, or null when no domain is created"
  value       = try(aws_cognito_user_pool_domain.this[0].cloudfront_distribution, null)
}

output "domain_cloudfront_distribution_zone_id" {
  description = "Route 53 hosted zone ID of the CloudFront distribution, or null when no domain is created"
  value       = try(aws_cognito_user_pool_domain.this[0].cloudfront_distribution_zone_id, null)
}

################################################################################
# Federation, resource servers and clients
################################################################################

output "client_ids" {
  description = "App client IDs keyed by client name"
  value       = { for name, client in aws_cognito_user_pool_client.this : name => client.id }
}

output "client_secrets" {
  description = "App client secrets keyed by client name, for clients created with generate_secret"
  value       = { for name, client in aws_cognito_user_pool_client.this : name => client.client_secret if var.clients[name].generate_secret }
  sensitive   = true
}

output "resource_server_scope_identifiers" {
  description = "Fully qualified scope names (<identifier>/<scope>) keyed by resource server identifier"
  value       = { for id, server in aws_cognito_resource_server.this : id => server.scope_identifiers }
}

output "managed_login_branding_ids" {
  description = "Managed login branding style IDs keyed by client name"
  value       = { for name, branding in aws_cognito_managed_login_branding.this : name => branding.managed_login_branding_id }
}

output "identity_provider_names" {
  description = "Names of the federated identity providers, for use in supported_identity_providers"
  value       = [for provider in aws_cognito_identity_provider.this : provider.provider_name]
}

output "user_group_names" {
  description = "Names of the user groups"
  value       = [for group in aws_cognito_user_group.this : group.name]
}

################################################################################
# Identity pool
################################################################################

output "identity_pool_id" {
  description = "ID of the identity pool, or null when not created"
  value       = try(aws_cognito_identity_pool.this[0].id, null)
}

output "identity_pool_arn" {
  description = "ARN of the identity pool, or null when not created"
  value       = try(aws_cognito_identity_pool.this[0].arn, null)
}
