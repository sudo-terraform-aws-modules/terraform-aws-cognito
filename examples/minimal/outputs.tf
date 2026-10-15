output "user_pool_id" {
  description = "ID of the user pool"
  value       = module.cognito.user_pool_id
}

output "client_ids" {
  description = "App client IDs keyed by client name"
  value       = module.cognito.client_ids
}
