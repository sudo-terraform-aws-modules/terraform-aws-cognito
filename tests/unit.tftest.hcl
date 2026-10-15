mock_provider "aws" {}

variables {
  name = "unit-test"
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = aws_cognito_user_pool.this.deletion_protection == "ACTIVE"
    error_message = "Deletion protection must default to ACTIVE."
  }

  assert {
    condition     = aws_cognito_user_pool.this.mfa_configuration == "ON"
    error_message = "MFA must default to ON."
  }

  assert {
    condition     = aws_cognito_user_pool.this.admin_create_user_config[0].allow_admin_create_user_only
    error_message = "Self sign-up must be off by default."
  }

  assert {
    condition     = aws_cognito_user_pool.this.password_policy[0].minimum_length == 14
    error_message = "Minimum password length must default to 14."
  }

  assert {
    condition     = aws_cognito_user_pool.this.user_attribute_update_settings[0].attributes_require_verification_before_update == toset(["email"])
    error_message = "Attribute update verification must follow auto_verified_attributes."
  }

  assert {
    condition     = length(aws_cognito_user_pool.this.user_pool_add_ons) == 0 && length(aws_cognito_risk_configuration.this) == 0
    error_message = "Threat protection must not be configured unless asked for."
  }
}

run "clients" {
  command = plan

  variables {
    clients = {
      spa = {}
      web = {
        generate_secret      = true
        allowed_oauth_flows  = ["code"]
        allowed_oauth_scopes = ["openid"]
        callback_urls        = ["https://app.example.com/cb"]
        refresh_token_rotation = {
          retry_grace_period_seconds = 10
        }
      }
      worker = {
        generate_secret      = true
        explicit_auth_flows  = []
        allowed_oauth_flows  = ["client_credentials"]
        allowed_oauth_scopes = ["https://api.example.com/read"]
      }
    }
  }

  assert {
    condition     = aws_cognito_user_pool_client.this["web"].explicit_auth_flows == toset(["ALLOW_USER_SRP_AUTH"])
    error_message = "Refresh token rotation must drop ALLOW_REFRESH_TOKEN_AUTH."
  }

  assert {
    condition     = aws_cognito_user_pool_client.this["spa"].explicit_auth_flows == toset(["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"])
    error_message = "Clients without rotation must keep the default flows."
  }

  assert {
    condition     = length(aws_cognito_user_pool_client.this["spa"].callback_urls) == 0 && !aws_cognito_user_pool_client.this["spa"].allowed_oauth_flows_user_pool_client
    error_message = "Non-OAuth clients must send empty lists so removed URLs are cleared."
  }

  assert {
    condition     = aws_cognito_user_pool_client.this["worker"].allowed_oauth_flows_user_pool_client
    error_message = "OAuth clients must enable allowed_oauth_flows_user_pool_client."
  }

  assert {
    condition     = aws_cognito_user_pool_client.this["web"].prevent_user_existence_errors == "ENABLED" && aws_cognito_user_pool_client.this["web"].enable_token_revocation
    error_message = "Clients must hide user existence errors and allow token revocation."
  }
}

run "oidc_provider" {
  command = plan

  variables {
    identity_providers = {
      EntraID = {
        provider_type = "OIDC"
        provider_details = {
          client_id                 = "client"
          oidc_issuer               = "https://login.microsoftonline.com/tenant/v2.0"
          authorize_scopes          = "openid email"
          attributes_request_method = "GET"
        }
      }
    }
    identity_provider_client_secrets = {
      EntraID = "secret"
    }
  }

  assert {
    condition     = nonsensitive(aws_cognito_identity_provider.this["EntraID"].provider_details["client_secret"]) == "secret"
    error_message = "The client secret must be merged into provider_details."
  }

  assert {
    condition     = nonsensitive(aws_cognito_identity_provider.this["EntraID"].provider_details["attributes_url_add_attributes"]) == "false"
    error_message = "OIDC providers must set attributes_url_add_attributes to avoid drift."
  }
}

run "managed_login_branding" {
  command = plan

  variables {
    domain                       = "unit-test"
    domain_managed_login_version = 2
    clients = {
      web = {
        allowed_oauth_flows  = ["code"]
        allowed_oauth_scopes = ["openid"]
        callback_urls        = ["https://app.example.com/cb"]
      }
      branded = {
        allowed_oauth_flows  = ["code"]
        allowed_oauth_scopes = ["openid"]
        callback_urls        = ["https://app.example.com/cb"]
        managed_login_branding = {
          settings = "{}"
        }
      }
      worker = {
        generate_secret      = true
        explicit_auth_flows  = []
        allowed_oauth_flows  = ["client_credentials"]
        allowed_oauth_scopes = ["https://api.example.com/read"]
      }
    }
  }

  assert {
    condition     = keys(aws_cognito_managed_login_branding.this) == ["branded", "web"]
    error_message = "Only code flow clients get a branding style."
  }

  assert {
    condition     = aws_cognito_managed_login_branding.this["web"].use_cognito_provided_values
    error_message = "Clients without settings must use the Cognito default style."
  }

  assert {
    condition     = aws_cognito_managed_login_branding.this["branded"].settings == "{}"
    error_message = "Clients with settings must send them instead of the Cognito default style."
  }
}

run "identity_pool_and_users" {
  command = plan

  variables {
    name    = "my-app.pool"
    clients = { mobile = {} }
    user_groups = {
      admin = {}
    }
    users = {
      "a@example.com" = { groups = ["admin"] }
    }
    identity_pool = {
      clients = ["mobile"]
    }
    identity_pool_roles = {
      authenticated_role_arn = "arn:aws:iam::111111111111:role/authenticated"
    }
  }

  assert {
    condition     = aws_cognito_identity_pool.this[0].identity_pool_name == "my_app_pool"
    error_message = "The identity pool name must be derived from the pool name with invalid characters replaced."
  }

  assert {
    condition     = !aws_cognito_identity_pool.this[0].allow_unauthenticated_identities
    error_message = "Guest access must be off by default."
  }

  assert {
    condition     = keys(aws_cognito_user_in_group.this) == ["a@example.com/admin"]
    error_message = "Group memberships must be keyed by user and group."
  }

  assert {
    condition     = aws_cognito_identity_pool_roles_attachment.this[0].roles == tomap({ authenticated = "arn:aws:iam::111111111111:role/authenticated" })
    error_message = "Only the authenticated role must be attached when no unauthenticated role is given."
  }
}

run "threat_protection_and_logging" {
  command = plan

  variables {
    user_pool_tier         = "PLUS"
    advanced_security_mode = "ENFORCED"
    risk_configuration     = {}
    log_delivery = [
      {
        event_source             = "userAuthEvents"
        log_level                = "INFO"
        cloudwatch_log_group_arn = "arn:aws:logs:eu-west-1:111111111111:log-group:/aws/vendedlogs/cognito"
      }
    ]
  }

  assert {
    condition     = aws_cognito_risk_configuration.this[0].compromised_credentials_risk_configuration[0].actions[0].event_action == "BLOCK"
    error_message = "Compromised credentials must be blocked by default."
  }

  assert {
    condition     = aws_cognito_risk_configuration.this[0].account_takeover_risk_configuration[0].actions[0].high_action[0].event_action == "BLOCK"
    error_message = "High risk sign-ins must be blocked by default."
  }

  assert {
    condition     = length(aws_cognito_log_delivery_configuration.this[0].log_configurations) == 1
    error_message = "Log delivery must be configured."
  }
}

run "rejects_implicit_grant" {
  command = plan

  variables {
    clients = {
      spa = {
        allowed_oauth_flows = ["implicit"]
      }
    }
  }

  expect_failures = [var.clients]
}

run "rejects_client_credentials_without_secret" {
  command = plan

  variables {
    clients = {
      worker = {
        allowed_oauth_flows = ["client_credentials"]
      }
    }
  }

  expect_failures = [var.clients]
}

run "rejects_secret_in_provider_details" {
  command = plan

  variables {
    identity_providers = {
      Google = {
        provider_type    = "Google"
        provider_details = { client_secret = "leak" }
      }
    }
  }

  expect_failures = [var.identity_providers]
}

run "rejects_log_delivery_without_single_destination" {
  command = plan

  variables {
    log_delivery = [
      {
        event_source = "userNotification"
        log_level    = "ERROR"
      }
    ]
  }

  expect_failures = [var.log_delivery]
}

run "rejects_user_notification_outside_cloudwatch" {
  command = plan

  variables {
    log_delivery = [
      {
        event_source  = "userNotification"
        log_level     = "ERROR"
        s3_bucket_arn = "arn:aws:s3:::logs"
      }
    ]
  }

  expect_failures = [var.log_delivery]
}
