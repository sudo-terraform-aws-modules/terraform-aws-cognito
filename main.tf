locals {
  attributes_require_verification = coalesce(var.attributes_require_verification_before_update, var.auto_verified_attributes)

  identity_pool_name = try(coalesce(var.identity_pool.name, replace(var.name, "/[^\\w ]/", "_")), null)

  # Managed login serves no pages to a client without a branding style
  branded_clients = {
    for name, client in var.clients : name => client
    if client.managed_login_branding != null || (var.domain != null && var.domain_managed_login_version == 2 && contains(client.allowed_oauth_flows, "code"))
  }

  user_group_memberships = merge({}, [
    for username, user in var.users : {
      for group in user.groups : "${username}/${group}" => {
        username = username
        group    = group
      }
    }
  ]...)
}

################################################################################
# User pool
################################################################################

resource "aws_cognito_user_pool" "this" {
  name                       = var.name
  region                     = var.region
  user_pool_tier             = var.user_pool_tier
  deletion_protection        = var.deletion_protection ? "ACTIVE" : "INACTIVE"
  mfa_configuration          = var.mfa_configuration
  username_attributes        = var.username_attributes
  alias_attributes           = var.alias_attributes
  auto_verified_attributes   = var.auto_verified_attributes
  sms_authentication_message = var.sms_authentication_message

  dynamic "username_configuration" {
    for_each = var.username_case_sensitive != null ? [1] : []

    content {
      case_sensitive = var.username_case_sensitive
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = var.allow_admin_create_user_only

    dynamic "invite_message_template" {
      for_each = var.invite_message_template[*]

      content {
        email_subject = invite_message_template.value.email_subject
        email_message = invite_message_template.value.email_message
        sms_message   = invite_message_template.value.sms_message
      }
    }
  }

  password_policy {
    minimum_length                   = var.password_policy.minimum_length
    require_lowercase                = var.password_policy.require_lowercase
    require_uppercase                = var.password_policy.require_uppercase
    require_numbers                  = var.password_policy.require_numbers
    require_symbols                  = var.password_policy.require_symbols
    temporary_password_validity_days = var.password_policy.temporary_password_validity_days
    password_history_size            = var.password_policy.password_history_size
  }

  dynamic "account_recovery_setting" {
    for_each = length(var.account_recovery_mechanisms) > 0 ? [1] : []

    content {
      dynamic "recovery_mechanism" {
        for_each = var.account_recovery_mechanisms

        content {
          name     = recovery_mechanism.value.name
          priority = recovery_mechanism.value.priority
        }
      }
    }
  }

  dynamic "software_token_mfa_configuration" {
    for_each = var.mfa_configuration != "OFF" ? [1] : []

    content {
      enabled = var.software_token_mfa_enabled
    }
  }

  dynamic "email_mfa_configuration" {
    for_each = var.mfa_configuration != "OFF" ? var.email_mfa_configuration[*] : []

    content {
      subject = email_mfa_configuration.value.subject
      message = email_mfa_configuration.value.message
    }
  }

  dynamic "user_attribute_update_settings" {
    for_each = length(local.attributes_require_verification) > 0 ? [1] : []

    content {
      attributes_require_verification_before_update = local.attributes_require_verification
    }
  }

  dynamic "device_configuration" {
    for_each = var.device_configuration[*]

    content {
      challenge_required_on_new_device      = device_configuration.value.challenge_required_on_new_device
      device_only_remembered_on_user_prompt = device_configuration.value.device_only_remembered_on_user_prompt
    }
  }

  dynamic "email_configuration" {
    for_each = var.email_configuration[*]

    content {
      email_sending_account  = email_configuration.value.email_sending_account
      source_arn             = email_configuration.value.source_arn
      from_email_address     = email_configuration.value.from_email_address
      reply_to_email_address = email_configuration.value.reply_to_email_address
      configuration_set      = email_configuration.value.configuration_set
    }
  }

  dynamic "sms_configuration" {
    for_each = var.sms_configuration[*]

    content {
      external_id    = sms_configuration.value.external_id
      sns_caller_arn = sms_configuration.value.sns_caller_arn
      sns_region     = sms_configuration.value.sns_region
    }
  }

  dynamic "verification_message_template" {
    for_each = var.verification_message_template[*]

    content {
      default_email_option  = verification_message_template.value.default_email_option
      email_subject         = verification_message_template.value.email_subject
      email_message         = verification_message_template.value.email_message
      email_subject_by_link = verification_message_template.value.email_subject_by_link
      email_message_by_link = verification_message_template.value.email_message_by_link
      sms_message           = verification_message_template.value.sms_message
    }
  }

  dynamic "lambda_config" {
    for_each = var.lambda_config[*]

    content {
      create_auth_challenge          = lambda_config.value.create_auth_challenge
      custom_message                 = lambda_config.value.custom_message
      define_auth_challenge          = lambda_config.value.define_auth_challenge
      post_authentication            = lambda_config.value.post_authentication
      post_confirmation              = lambda_config.value.post_confirmation
      pre_authentication             = lambda_config.value.pre_authentication
      pre_sign_up                    = lambda_config.value.pre_sign_up
      user_migration                 = lambda_config.value.user_migration
      verify_auth_challenge_response = lambda_config.value.verify_auth_challenge_response
      kms_key_id                     = lambda_config.value.kms_key_id

      dynamic "pre_token_generation_config" {
        for_each = lambda_config.value.pre_token_generation_config[*]

        content {
          lambda_arn     = pre_token_generation_config.value.lambda_arn
          lambda_version = pre_token_generation_config.value.lambda_version
        }
      }

      dynamic "custom_email_sender" {
        for_each = lambda_config.value.custom_email_sender[*]

        content {
          lambda_arn     = custom_email_sender.value.lambda_arn
          lambda_version = custom_email_sender.value.lambda_version
        }
      }

      dynamic "custom_sms_sender" {
        for_each = lambda_config.value.custom_sms_sender[*]

        content {
          lambda_arn     = custom_sms_sender.value.lambda_arn
          lambda_version = custom_sms_sender.value.lambda_version
        }
      }
    }
  }

  dynamic "schema" {
    for_each = var.schema_attributes

    content {
      name                     = schema.value.name
      attribute_data_type      = schema.value.attribute_data_type
      mutable                  = schema.value.mutable
      required                 = schema.value.required
      developer_only_attribute = schema.value.developer_only_attribute

      dynamic "string_attribute_constraints" {
        for_each = schema.value.string_attribute_constraints[*]

        content {
          min_length = string_attribute_constraints.value.min_length
          max_length = string_attribute_constraints.value.max_length
        }
      }

      dynamic "number_attribute_constraints" {
        for_each = schema.value.number_attribute_constraints[*]

        content {
          min_value = number_attribute_constraints.value.min_value
          max_value = number_attribute_constraints.value.max_value
        }
      }
    }
  }

  dynamic "sign_in_policy" {
    for_each = var.allowed_first_auth_factors != null ? [1] : []

    content {
      allowed_first_auth_factors = var.allowed_first_auth_factors
    }
  }

  dynamic "web_authn_configuration" {
    for_each = var.web_authn_configuration[*]

    content {
      relying_party_id  = web_authn_configuration.value.relying_party_id
      user_verification = web_authn_configuration.value.user_verification
    }
  }

  dynamic "user_pool_add_ons" {
    for_each = var.advanced_security_mode != null ? [1] : []

    content {
      advanced_security_mode = var.advanced_security_mode

      dynamic "advanced_security_additional_flows" {
        for_each = var.advanced_security_custom_auth_mode != null ? [1] : []

        content {
          custom_auth_mode = var.advanced_security_custom_auth_mode
        }
      }
    }
  }

  tags = var.tags
}

resource "aws_cognito_risk_configuration" "this" {
  count = var.risk_configuration != null ? 1 : 0

  region       = var.region
  user_pool_id = aws_cognito_user_pool.this.id

  compromised_credentials_risk_configuration {
    event_filter = var.risk_configuration.compromised_credentials_event_filter

    actions {
      event_action = var.risk_configuration.compromised_credentials_action
    }
  }

  account_takeover_risk_configuration {
    actions {
      low_action {
        event_action = var.risk_configuration.account_takeover.low_action.event_action
        notify       = var.risk_configuration.account_takeover.low_action.notify
      }

      medium_action {
        event_action = var.risk_configuration.account_takeover.medium_action.event_action
        notify       = var.risk_configuration.account_takeover.medium_action.notify
      }

      high_action {
        event_action = var.risk_configuration.account_takeover.high_action.event_action
        notify       = var.risk_configuration.account_takeover.high_action.notify
      }
    }

    dynamic "notify_configuration" {
      for_each = var.risk_configuration.account_takeover.notify_configuration[*]

      content {
        source_arn = notify_configuration.value.source_arn
        from       = notify_configuration.value.from
        reply_to   = notify_configuration.value.reply_to
      }
    }
  }

  dynamic "risk_exception_configuration" {
    for_each = var.risk_configuration.blocked_ip_ranges != null || var.risk_configuration.skipped_ip_ranges != null ? [1] : []

    content {
      blocked_ip_range_list = var.risk_configuration.blocked_ip_ranges
      skipped_ip_range_list = var.risk_configuration.skipped_ip_ranges
    }
  }
}

resource "aws_cognito_log_delivery_configuration" "this" {
  count = length(var.log_delivery) > 0 ? 1 : 0

  region       = var.region
  user_pool_id = aws_cognito_user_pool.this.id

  dynamic "log_configurations" {
    for_each = var.log_delivery

    content {
      event_source = log_configurations.value.event_source
      log_level    = log_configurations.value.log_level

      dynamic "cloud_watch_logs_configuration" {
        for_each = log_configurations.value.cloudwatch_log_group_arn[*]

        content {
          log_group_arn = cloud_watch_logs_configuration.value
        }
      }

      dynamic "firehose_configuration" {
        for_each = log_configurations.value.firehose_stream_arn[*]

        content {
          stream_arn = firehose_configuration.value
        }
      }

      dynamic "s3_configuration" {
        for_each = log_configurations.value.s3_bucket_arn[*]

        content {
          bucket_arn = s3_configuration.value
        }
      }
    }
  }
}

resource "aws_cognito_user_pool_domain" "this" {
  count = var.domain != null ? 1 : 0

  region                = var.region
  domain                = var.domain
  certificate_arn       = var.domain_certificate_arn
  managed_login_version = var.domain_managed_login_version
  user_pool_id          = aws_cognito_user_pool.this.id
}

################################################################################
# Federation, resource servers and clients
################################################################################

resource "aws_cognito_identity_provider" "this" {
  for_each = var.identity_providers

  region        = var.region
  user_pool_id  = aws_cognito_user_pool.this.id
  provider_name = each.key
  provider_type = each.value.provider_type
  # Cognito adds attributes_url_add_attributes to OIDC providers on read, which shows as drift otherwise
  provider_details = merge(
    each.value.provider_type == "OIDC" ? { attributes_url_add_attributes = "false" } : {},
    each.value.provider_details,
    { for name, secret in var.identity_provider_client_secrets : "client_secret" => secret if name == each.key },
  )
  attribute_mapping = each.value.attribute_mapping
  idp_identifiers   = each.value.idp_identifiers
}

resource "aws_cognito_resource_server" "this" {
  for_each = var.resource_servers

  region       = var.region
  user_pool_id = aws_cognito_user_pool.this.id
  identifier   = each.key
  name         = coalesce(each.value.name, each.key)

  dynamic "scope" {
    for_each = each.value.scopes

    content {
      scope_name        = scope.key
      scope_description = scope.value
    }
  }
}

resource "aws_cognito_user_pool_client" "this" {
  for_each = var.clients

  region       = var.region
  name         = each.key
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret                               = each.value.generate_secret
  explicit_auth_flows                           = try(each.value.refresh_token_rotation.enabled, false) ? [for f in each.value.explicit_auth_flows : f if f != "ALLOW_REFRESH_TOKEN_AUTH"] : each.value.explicit_auth_flows
  allowed_oauth_flows_user_pool_client          = length(each.value.allowed_oauth_flows) > 0
  allowed_oauth_flows                           = each.value.allowed_oauth_flows
  allowed_oauth_scopes                          = each.value.allowed_oauth_scopes
  callback_urls                                 = each.value.callback_urls
  logout_urls                                   = each.value.logout_urls
  default_redirect_uri                          = each.value.default_redirect_uri
  supported_identity_providers                  = each.value.supported_identity_providers
  read_attributes                               = each.value.read_attributes
  write_attributes                              = each.value.write_attributes
  access_token_validity                         = each.value.access_token_validity
  id_token_validity                             = each.value.id_token_validity
  refresh_token_validity                        = each.value.refresh_token_validity
  auth_session_validity                         = each.value.auth_session_validity
  enable_token_revocation                       = each.value.enable_token_revocation
  prevent_user_existence_errors                 = each.value.prevent_user_existence_errors
  enable_propagate_additional_user_context_data = each.value.enable_propagate_additional_user_context_data

  token_validity_units {
    access_token  = each.value.token_validity_units.access_token
    id_token      = each.value.token_validity_units.id_token
    refresh_token = each.value.token_validity_units.refresh_token
  }

  dynamic "refresh_token_rotation" {
    for_each = each.value.refresh_token_rotation[*]

    content {
      feature                    = refresh_token_rotation.value.enabled ? "ENABLED" : "DISABLED"
      retry_grace_period_seconds = refresh_token_rotation.value.retry_grace_period_seconds
    }
  }

  # Clients reference provider names and custom scopes, which must exist first
  depends_on = [
    aws_cognito_identity_provider.this,
    aws_cognito_resource_server.this,
  ]
}

resource "aws_cognito_managed_login_branding" "this" {
  for_each = local.branded_clients

  region                      = var.region
  user_pool_id                = aws_cognito_user_pool.this.id
  client_id                   = aws_cognito_user_pool_client.this[each.key].id
  settings                    = try(each.value.managed_login_branding.settings, null)
  use_cognito_provided_values = try(each.value.managed_login_branding.settings, null) == null && length(try(each.value.managed_login_branding.assets, [])) == 0 ? true : null

  dynamic "asset" {
    for_each = try(each.value.managed_login_branding.assets, [])

    content {
      category   = asset.value.category
      color_mode = asset.value.color_mode
      extension  = asset.value.extension
      bytes      = asset.value.bytes
    }
  }
}

resource "aws_cognito_user_pool_ui_customization" "this" {
  count = var.domain != null && var.hosted_ui_customization != null ? 1 : 0

  region     = var.region
  css        = var.hosted_ui_customization.css
  image_file = var.hosted_ui_customization.image_file

  # The domain must exist before the hosted UI can be customised
  user_pool_id = aws_cognito_user_pool_domain.this[0].user_pool_id
}

################################################################################
# Groups and bootstrap users
################################################################################

resource "aws_cognito_user_group" "this" {
  for_each = var.user_groups

  region       = var.region
  user_pool_id = aws_cognito_user_pool.this.id
  name         = each.key
  description  = each.value.description
  precedence   = each.value.precedence
  role_arn     = each.value.role_arn
}

resource "aws_cognito_user" "this" {
  for_each = var.users

  region                   = var.region
  user_pool_id             = aws_cognito_user_pool.this.id
  username                 = each.key
  attributes               = each.value.attributes
  desired_delivery_mediums = each.value.desired_delivery_mediums
  enabled                  = each.value.enabled
  message_action           = each.value.message_action
}

resource "aws_cognito_user_in_group" "this" {
  for_each = local.user_group_memberships

  region       = var.region
  user_pool_id = aws_cognito_user_pool.this.id
  username     = aws_cognito_user.this[each.value.username].username
  group_name   = try(aws_cognito_user_group.this[each.value.group].name, each.value.group)
}

################################################################################
# Identity pool
################################################################################

resource "aws_cognito_identity_pool" "this" {
  count = var.identity_pool != null ? 1 : 0

  region                           = var.region
  identity_pool_name               = local.identity_pool_name
  allow_unauthenticated_identities = var.identity_pool.allow_unauthenticated_identities
  allow_classic_flow               = var.identity_pool.allow_classic_flow
  supported_login_providers        = var.identity_pool.supported_login_providers
  openid_connect_provider_arns     = var.identity_pool.openid_connect_provider_arns
  saml_provider_arns               = var.identity_pool.saml_provider_arns
  developer_provider_name          = var.identity_pool.developer_provider_name

  dynamic "cognito_identity_providers" {
    for_each = toset(var.identity_pool.clients)

    content {
      provider_name           = aws_cognito_user_pool.this.endpoint
      client_id               = aws_cognito_user_pool_client.this[cognito_identity_providers.key].id
      server_side_token_check = var.identity_pool.server_side_token_check
    }
  }

  tags = var.tags
}

resource "aws_cognito_identity_pool_roles_attachment" "this" {
  count = var.identity_pool != null && var.identity_pool_roles != null ? 1 : 0

  region           = var.region
  identity_pool_id = aws_cognito_identity_pool.this[0].id

  roles = merge(
    { authenticated = var.identity_pool_roles.authenticated_role_arn },
    var.identity_pool_roles.unauthenticated_role_arn != null ? { unauthenticated = var.identity_pool_roles.unauthenticated_role_arn } : {},
  )

  dynamic "role_mapping" {
    for_each = var.identity_pool_roles.role_mappings

    content {
      identity_provider         = "${aws_cognito_user_pool.this.endpoint}:${aws_cognito_user_pool_client.this[role_mapping.key].id}"
      type                      = role_mapping.value.type
      ambiguous_role_resolution = role_mapping.value.ambiguous_role_resolution

      dynamic "mapping_rule" {
        for_each = role_mapping.value.rules

        content {
          claim      = mapping_rule.value.claim
          match_type = mapping_rule.value.match_type
          value      = mapping_rule.value.value
          role_arn   = mapping_rule.value.role_arn
        }
      }
    }
  }
}
