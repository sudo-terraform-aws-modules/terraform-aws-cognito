################################################################################
# User pool
################################################################################

variable "name" {
  description = "Name of the user pool. Also used as the default identity pool name"
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 128
    error_message = "name must be between 1 and 128 characters."
  }
}

variable "region" {
  description = "Region to manage the resources in. Defaults to the provider region"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the user pool and identity pool"
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "user_pool_tier" {
  description = "Feature plan of the user pool: LITE, ESSENTIALS or PLUS. Threat protection (advanced_security_mode) needs PLUS"
  type        = string
  default     = "ESSENTIALS"
  nullable    = false

  validation {
    condition     = contains(["LITE", "ESSENTIALS", "PLUS"], var.user_pool_tier)
    error_message = "user_pool_tier must be one of LITE, ESSENTIALS or PLUS."
  }
}

variable "deletion_protection" {
  description = "Block deletion of the user pool. Must be set to false and applied before the pool can be destroyed"
  type        = bool
  default     = true
  nullable    = false
}

variable "username_attributes" {
  description = "Attributes users sign in with instead of a username (email, phone_number). Conflicts with alias_attributes. Cannot be changed after creation"
  type        = list(string)
  default     = ["email"]
}

variable "alias_attributes" {
  description = "Attributes that can be used as aliases for the username (email, phone_number, preferred_username). Conflicts with username_attributes. Cannot be changed after creation"
  type        = list(string)
  default     = null
}

variable "username_case_sensitive" {
  description = "Whether usernames and aliases are case sensitive. Cannot be changed after creation"
  type        = bool
  default     = false
  nullable    = false
}

variable "auto_verified_attributes" {
  description = "Attributes Cognito verifies automatically by sending a code (email, phone_number)"
  type        = list(string)
  default     = ["email"]
  nullable    = false
}

variable "attributes_require_verification_before_update" {
  description = "Attributes that keep their old value until the new one is verified. Defaults to auto_verified_attributes; set to [] to disable"
  type        = list(string)
  default     = null
}

variable "allow_admin_create_user_only" {
  description = "Allow only administrators to create users. Set to false to enable self sign-up"
  type        = bool
  default     = true
  nullable    = false
}

variable "invite_message_template" {
  description = "Invitation message sent to users created by an administrator. Messages must contain {username} and {####}"
  type = object({
    email_subject = optional(string)
    email_message = optional(string)
    sms_message   = optional(string)
  })
  default = null
}

variable "password_policy" {
  description = "Password policy for the user pool"
  type = object({
    minimum_length                   = optional(number, 14)
    require_lowercase                = optional(bool, true)
    require_uppercase                = optional(bool, true)
    require_numbers                  = optional(bool, true)
    require_symbols                  = optional(bool, true)
    temporary_password_validity_days = optional(number, 3)
    password_history_size            = optional(number)
  })
  default  = {}
  nullable = false

  validation {
    condition     = var.password_policy.minimum_length >= 8 && var.password_policy.minimum_length <= 99
    error_message = "password_policy.minimum_length must be between 8 and 99."
  }
}

variable "mfa_configuration" {
  description = "MFA enforcement: OFF, ON or OPTIONAL"
  type        = string
  default     = "ON"
  nullable    = false

  validation {
    condition     = contains(["OFF", "ON", "OPTIONAL"], var.mfa_configuration)
    error_message = "mfa_configuration must be one of OFF, ON or OPTIONAL."
  }
}

variable "software_token_mfa_enabled" {
  description = "Allow authenticator app (TOTP) MFA. Ignored when mfa_configuration is OFF"
  type        = bool
  default     = true
  nullable    = false
}

variable "email_mfa_configuration" {
  description = "Enables email MFA with the given message. Needs ESSENTIALS or PLUS and email_configuration with DEVELOPER sending. The message must contain {####}"
  type = object({
    subject = optional(string)
    message = optional(string)
  })
  default = null
}

variable "sms_authentication_message" {
  description = "SMS MFA message. Must contain {####}"
  type        = string
  default     = null
}

variable "account_recovery_mechanisms" {
  description = "Account recovery options in priority order: verified_email, verified_phone_number or admin_only"
  type = list(object({
    name     = string
    priority = number
  }))
  default = [
    {
      name     = "verified_email"
      priority = 1
    }
  ]
  nullable = false
}

variable "device_configuration" {
  description = "Device tracking settings. Remembered devices can skip MFA, so leave unset unless that is intended"
  type = object({
    challenge_required_on_new_device      = optional(bool, true)
    device_only_remembered_on_user_prompt = optional(bool, true)
  })
  default = null
}

variable "email_configuration" {
  description = "Email sending settings. Without this Cognito sends from its own address with a low daily quota, which is not suitable for production"
  type = object({
    email_sending_account  = optional(string, "DEVELOPER")
    source_arn             = optional(string)
    from_email_address     = optional(string)
    reply_to_email_address = optional(string)
    configuration_set      = optional(string)
  })
  default = null

  validation {
    condition     = var.email_configuration == null || contains(["COGNITO_DEFAULT", "DEVELOPER"], try(var.email_configuration.email_sending_account, ""))
    error_message = "email_configuration.email_sending_account must be COGNITO_DEFAULT or DEVELOPER."
  }
}

variable "sms_configuration" {
  description = "SNS settings for SMS messages. The role must trust cognito-idp.amazonaws.com with the given external ID"
  type = object({
    external_id    = string
    sns_caller_arn = string
    sns_region     = optional(string)
  })
  default = null
}

variable "verification_message_template" {
  description = "Messages sent to verify email addresses and phone numbers"
  type = object({
    default_email_option  = optional(string)
    email_subject         = optional(string)
    email_message         = optional(string)
    email_subject_by_link = optional(string)
    email_message_by_link = optional(string)
    sms_message           = optional(string)
  })
  default = null
}

variable "lambda_config" {
  description = "Lambda triggers. Each function needs an aws_lambda_permission allowing cognito-idp.amazonaws.com with the user pool ARN as source_arn"
  type = object({
    create_auth_challenge          = optional(string)
    custom_message                 = optional(string)
    define_auth_challenge          = optional(string)
    post_authentication            = optional(string)
    post_confirmation              = optional(string)
    pre_authentication             = optional(string)
    pre_sign_up                    = optional(string)
    user_migration                 = optional(string)
    verify_auth_challenge_response = optional(string)
    kms_key_id                     = optional(string)
    pre_token_generation_config = optional(object({
      lambda_arn     = string
      lambda_version = optional(string, "V2_0")
    }))
    custom_email_sender = optional(object({
      lambda_arn     = string
      lambda_version = optional(string, "V1_0")
    }))
    custom_sms_sender = optional(object({
      lambda_arn     = string
      lambda_version = optional(string, "V1_0")
    }))
  })
  default = null
}

variable "schema_attributes" {
  description = "Custom attributes. Attributes can be added later but not changed or removed"
  type = list(object({
    name                     = string
    attribute_data_type      = string
    mutable                  = optional(bool, true)
    required                 = optional(bool, false)
    developer_only_attribute = optional(bool, false)
    string_attribute_constraints = optional(object({
      min_length = optional(string)
      max_length = optional(string)
    }))
    number_attribute_constraints = optional(object({
      min_value = optional(string)
      max_value = optional(string)
    }))
  }))
  default  = []
  nullable = false

  validation {
    condition = alltrue([
      for a in var.schema_attributes : contains(["String", "Number", "DateTime", "Boolean"], a.attribute_data_type)
    ])
    error_message = "schema_attributes attribute_data_type must be String, Number, DateTime or Boolean."
  }
}

variable "allowed_first_auth_factors" {
  description = "Sign-in factors offered in choice-based authentication (PASSWORD, EMAIL_OTP, SMS_OTP, WEB_AUTHN). Needs ESSENTIALS or PLUS"
  type        = list(string)
  default     = null
}

variable "web_authn_configuration" {
  description = "Passkey settings. relying_party_id defaults to the user pool domain"
  type = object({
    relying_party_id  = optional(string)
    user_verification = optional(string, "required")
  })
  default = null
}

variable "advanced_security_mode" {
  description = "Threat protection for standard authentication: OFF, AUDIT or ENFORCED. Needs PLUS"
  type        = string
  default     = null

  validation {
    condition     = var.advanced_security_mode == null || contains(["OFF", "AUDIT", "ENFORCED"], coalesce(var.advanced_security_mode, "OFF"))
    error_message = "advanced_security_mode must be one of OFF, AUDIT or ENFORCED."
  }
}

variable "advanced_security_custom_auth_mode" {
  description = "Threat protection for custom authentication flows: AUDIT or ENFORCED. Needs advanced_security_mode"
  type        = string
  default     = null

  validation {
    condition     = var.advanced_security_custom_auth_mode == null || contains(["AUDIT", "ENFORCED"], coalesce(var.advanced_security_custom_auth_mode, "AUDIT"))
    error_message = "advanced_security_custom_auth_mode must be AUDIT or ENFORCED."
  }
}

variable "risk_configuration" {
  description = "Threat protection responses for the whole pool. Needs PLUS and advanced_security_mode = ENFORCED. Event actions are BLOCK, MFA_IF_CONFIGURED, MFA_REQUIRED or NO_ACTION. notify needs notify_configuration with a verified SES identity"
  type = object({
    compromised_credentials_action       = optional(string, "BLOCK")
    compromised_credentials_event_filter = optional(list(string), ["SIGN_IN", "PASSWORD_CHANGE", "SIGN_UP"])
    account_takeover = optional(object({
      low_action = optional(object({
        event_action = string
        notify       = optional(bool, false)
      }), { event_action = "NO_ACTION" })
      medium_action = optional(object({
        event_action = string
        notify       = optional(bool, false)
      }), { event_action = "MFA_IF_CONFIGURED" })
      high_action = optional(object({
        event_action = string
        notify       = optional(bool, false)
      }), { event_action = "BLOCK" })
      notify_configuration = optional(object({
        source_arn = string
        from       = optional(string)
        reply_to   = optional(string)
      }))
    }), {})
    blocked_ip_ranges = optional(list(string))
    skipped_ip_ranges = optional(list(string))
  })
  default = null

  validation {
    condition = var.risk_configuration == null || alltrue([
      for a in try([
        var.risk_configuration.account_takeover.low_action.event_action,
        var.risk_configuration.account_takeover.medium_action.event_action,
        var.risk_configuration.account_takeover.high_action.event_action,
      ], []) : contains(["BLOCK", "MFA_IF_CONFIGURED", "MFA_REQUIRED", "NO_ACTION"], a)
    ])
    error_message = "account_takeover event_action must be BLOCK, MFA_IF_CONFIGURED, MFA_REQUIRED or NO_ACTION."
  }

  validation {
    condition     = var.risk_configuration == null || contains(["BLOCK", "NO_ACTION"], try(var.risk_configuration.compromised_credentials_action, ""))
    error_message = "compromised_credentials_action must be BLOCK or NO_ACTION."
  }
}

variable "log_delivery" {
  description = "Exports user pool logs. userNotification at ERROR covers message delivery failures on any tier; userAuthEvents at INFO records sign-in activity and needs PLUS. Set exactly one destination per entry"
  type = list(object({
    event_source             = string
    log_level                = string
    cloudwatch_log_group_arn = optional(string)
    firehose_stream_arn      = optional(string)
    s3_bucket_arn            = optional(string)
  }))
  default  = []
  nullable = false

  validation {
    condition = alltrue([
      for l in var.log_delivery : contains(["userNotification", "userAuthEvents"], l.event_source) && contains(["ERROR", "INFO"], l.log_level)
    ])
    error_message = "log_delivery event_source must be userNotification or userAuthEvents, and log_level ERROR or INFO."
  }

  validation {
    condition = alltrue([
      for l in var.log_delivery : length(compact([l.cloudwatch_log_group_arn, l.firehose_stream_arn, l.s3_bucket_arn])) == 1
    ])
    error_message = "Each log_delivery entry needs exactly one of cloudwatch_log_group_arn, firehose_stream_arn or s3_bucket_arn."
  }

  validation {
    condition     = alltrue([for l in var.log_delivery : l.event_source != "userNotification" || l.cloudwatch_log_group_arn != null])
    error_message = "userNotification logs can only be delivered to CloudWatch Logs."
  }
}

################################################################################
# Domain
################################################################################

variable "domain" {
  description = "Domain prefix (for <prefix>.auth.<region>.amazoncognito.com) or a fully qualified custom domain. A custom domain also needs domain_certificate_arn"
  type        = string
  default     = null
}

variable "domain_certificate_arn" {
  description = "ACM certificate ARN for a custom domain. The certificate must be in us-east-1"
  type        = string
  default     = null
}

variable "hosted_ui_customization" {
  description = "CSS and logo for the classic hosted UI (domain_managed_login_version 1), applied to every client. image_file is the base64 encoded logo"
  type = object({
    css        = optional(string)
    image_file = optional(string)
  })
  default = null
}

variable "domain_managed_login_version" {
  description = "1 for the classic hosted UI, 2 for managed login. With 2, every client using the code flow gets a branding style, the Cognito default unless managed_login_branding is set on the client"
  type        = number
  default     = null

  validation {
    condition     = var.domain_managed_login_version == null || contains([1, 2], coalesce(var.domain_managed_login_version, 1))
    error_message = "domain_managed_login_version must be 1 or 2."
  }
}

################################################################################
# Resource servers, clients, groups and identity providers
################################################################################

variable "resource_servers" {
  description = "OAuth resource servers keyed by identifier, usually the API URL. scopes maps scope name to description"
  type = map(object({
    name   = optional(string)
    scopes = optional(map(string), {})
  }))
  default  = {}
  nullable = false
}

variable "clients" {
  description = "App clients keyed by client name. Token validity units default to minutes for access and ID tokens and days for refresh tokens. Enabling refresh_token_rotation removes ALLOW_REFRESH_TOKEN_AUTH from explicit_auth_flows, since Cognito rejects the two together"
  type = map(object({
    generate_secret               = optional(bool, false)
    explicit_auth_flows           = optional(list(string), ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"])
    allowed_oauth_flows           = optional(list(string), [])
    allowed_oauth_scopes          = optional(list(string), [])
    callback_urls                 = optional(list(string), [])
    logout_urls                   = optional(list(string), [])
    default_redirect_uri          = optional(string)
    supported_identity_providers  = optional(list(string), ["COGNITO"])
    read_attributes               = optional(list(string))
    write_attributes              = optional(list(string))
    access_token_validity         = optional(number, 60)
    id_token_validity             = optional(number, 60)
    refresh_token_validity        = optional(number, 30)
    auth_session_validity         = optional(number, 3)
    enable_token_revocation       = optional(bool, true)
    prevent_user_existence_errors = optional(string, "ENABLED")
    token_validity_units = optional(object({
      access_token  = optional(string, "minutes")
      id_token      = optional(string, "minutes")
      refresh_token = optional(string, "days")
    }), {})
    enable_propagate_additional_user_context_data = optional(bool, false)
    refresh_token_rotation = optional(object({
      enabled                    = optional(bool, true)
      retry_grace_period_seconds = optional(number)
    }))
    managed_login_branding = optional(object({
      settings = optional(string)
      assets = optional(list(object({
        category   = string
        color_mode = string
        extension  = string
        bytes      = string
      })), [])
    }))
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue(flatten([
      for c in var.clients : [for f in c.allowed_oauth_flows : contains(["code", "client_credentials"], f)]
    ]))
    error_message = "allowed_oauth_flows may only contain code or client_credentials. The implicit grant exposes tokens in the browser URL and is not supported."
  }

  validation {
    condition     = alltrue([for c in var.clients : contains(["ENABLED", "LEGACY"], c.prevent_user_existence_errors)])
    error_message = "prevent_user_existence_errors must be ENABLED or LEGACY."
  }

  validation {
    condition = alltrue([
      for c in var.clients : !contains(c.allowed_oauth_flows, "client_credentials") || c.generate_secret
    ])
    error_message = "Clients using client_credentials must set generate_secret = true."
  }
}

variable "user_groups" {
  description = "User groups keyed by group name. Lower precedence wins when a user is in several groups with roles"
  type = map(object({
    description = optional(string)
    precedence  = optional(number)
    role_arn    = optional(string)
  }))
  default  = {}
  nullable = false
}

variable "identity_providers" {
  description = "Federated identity providers keyed by provider name. Put OIDC and social client secrets in identity_provider_client_secrets instead of provider_details"
  type = map(object({
    provider_type     = string
    provider_details  = map(string)
    attribute_mapping = optional(map(string))
    idp_identifiers   = optional(list(string))
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for p in var.identity_providers : contains(["SAML", "OIDC", "Google", "Facebook", "LoginWithAmazon", "SignInWithApple"], p.provider_type)
    ])
    error_message = "provider_type must be one of SAML, OIDC, Google, Facebook, LoginWithAmazon or SignInWithApple."
  }

  validation {
    condition     = alltrue([for p in var.identity_providers : !contains(keys(p.provider_details), "client_secret")])
    error_message = "Pass client secrets through identity_provider_client_secrets so they stay out of plan output."
  }
}

variable "identity_provider_client_secrets" {
  description = "Client secrets for identity providers, keyed by provider name. Merged into provider_details as client_secret"
  type        = map(string)
  default     = {}
  sensitive   = true
  nullable    = false
}

variable "users" {
  description = "Users to bootstrap, keyed by username. Cognito delivers a temporary password, so no password passes through Terraform. Meant for initial administrators, not for managing the user base"
  type = map(object({
    attributes               = optional(map(string), {})
    groups                   = optional(list(string), [])
    desired_delivery_mediums = optional(list(string), ["EMAIL"])
    enabled                  = optional(bool, true)
    message_action           = optional(string)
  }))
  default  = {}
  nullable = false
}

################################################################################
# Identity pool
################################################################################

variable "identity_pool" {
  description = "Identity pool that exchanges sign-ins for AWS credentials. Not created when null. clients lists names from var.clients allowed to use the pool"
  type = object({
    name                             = optional(string)
    allow_unauthenticated_identities = optional(bool, false)
    allow_classic_flow               = optional(bool, false)
    clients                          = optional(list(string), [])
    server_side_token_check          = optional(bool, true)
    supported_login_providers        = optional(map(string))
    openid_connect_provider_arns     = optional(list(string))
    saml_provider_arns               = optional(list(string))
    developer_provider_name          = optional(string)
  })
  default = null

  validation {
    condition     = var.identity_pool == null || try(length(var.identity_pool.clients) > 0 || var.identity_pool.supported_login_providers != null, false)
    error_message = "identity_pool needs at least one entry in clients or supported_login_providers."
  }
}

variable "identity_pool_roles" {
  description = "IAM roles for the identity pool. Kept apart from identity_pool so the roles can trust the pool through the cognito-identity.amazonaws.com:aud condition on identity_pool_id without a cycle. role_mappings is keyed by a client name from var.clients; Token reads the cognito:preferred_role claim from group membership, Rules matches claims in order."
  type = object({
    authenticated_role_arn   = string
    unauthenticated_role_arn = optional(string)
    role_mappings = optional(map(object({
      type                      = string
      ambiguous_role_resolution = optional(string, "Deny")
      rules = optional(list(object({
        claim      = string
        match_type = string
        value      = string
        role_arn   = string
      })), [])
    })), {})
  })
  default = null

  validation {
    condition = var.identity_pool_roles == null || alltrue([
      for m in try(values(var.identity_pool_roles.role_mappings), []) : contains(["Token", "Rules"], m.type)
    ])
    error_message = "role_mappings type must be Token or Rules."
  }
}
