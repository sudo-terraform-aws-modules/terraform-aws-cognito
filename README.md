# terraform-aws-cognito

[![Terraform CI](https://github.com/sudo-terraform-aws-modules/terraform-aws-cognito/actions/workflows/main.yml/badge.svg)](https://github.com/sudo-terraform-aws-modules/terraform-aws-cognito/actions/workflows/main.yml) [![Terraform](https://img.shields.io/badge/terraform-%3E%3D1.3.0-7B42BC?logo=terraform)](versions.tf) [![AWS provider](https://img.shields.io/badge/aws%20provider-%3E%3D6.13.0-FF9900)](versions.tf) [![License](https://img.shields.io/github/license/sudo-terraform-aws-modules/terraform-aws-cognito)](LICENSE)

<img width="600" alt="SUDO x AWS" src="https://github.com/user-attachments/assets/f7044ff9-afce-4811-91c6-2f3c95635abb" />

Terraform module that creates an Amazon Cognito user pool together with the pieces that usually sit around it: the login domain, app clients, OAuth resource servers, user groups, federated identity providers, bootstrap users and an optional identity pool.

The defaults favour a staff or B2B login rather than a public sign-up page: administrators create users, MFA is required, passwords need 14 characters, deletion protection is on, user existence errors are hidden and token revocation is enabled. Relax them per pool where the use case needs it.

## Usage

```hcl
module "cognito" {
  source  = "sudo-terraform-aws-modules/cognito/aws"
  version = "1.0.0"

  name   = "acme-console"
  domain = "acme-console"

  clients = {
    console = {
      generate_secret      = true
      allowed_oauth_flows  = ["code"]
      allowed_oauth_scopes = ["openid", "email", "profile"]
      callback_urls        = ["https://console.acme.com/auth"]
    }
  }

  user_groups = {
    admin     = { description = "Administrators", precedence = 1 }
    developer = { description = "Developers", precedence = 10 }
  }

  users = {
    "first.admin@acme.com" = {
      attributes = {
        email          = "first.admin@acme.com"
        email_verified = "true"
      }
      groups = ["admin"]
    }
  }
}
```

See [examples/minimal](examples/minimal) and [examples/complete](examples/complete). The complete example federates Microsoft Entra ID over OIDC, adds a machine-to-machine client with custom scopes and wires an identity pool to IAM roles that trust only that pool.

## Things to know before you apply

**Settings fixed at creation.** `username_attributes`, `alias_attributes`, `username_case_sensitive` and existing `schema_attributes` cannot be changed on a live pool. Changing them fails or replaces the pool, and replacing a pool deletes every user in it.

**Deletion protection.** `deletion_protection` defaults to `true`. To destroy a pool, apply with it set to `false` first.

**Email delivery.** Without `email_configuration`, Cognito sends mail from its own address with a small daily quota. Production pools should send through SES with `email_sending_account = "DEVELOPER"`.

**Feature plans.** `user_pool_tier` defaults to `ESSENTIALS`, which is also what AWS picks for a new pool. Threat protection (`advanced_security_mode`) needs `PLUS`, which costs more per monthly active user. `LITE` is the cheapest but drops features such as choice-based sign-in and email MFA.

**Client secrets.** Federation client secrets go in `identity_provider_client_secrets`, a sensitive variable, so they stay out of plan output. They are still written to state, as are app client secrets exposed through the sensitive `client_secrets` output. Keep state encrypted and access to it narrow.

**Lambda triggers.** The module sets the triggers but does not touch Lambda resource policies. Add an `aws_lambda_permission` for `cognito-idp.amazonaws.com` with `source_arn = module.cognito.user_pool_arn` for each function.

**Identity pool roles.** The roles are a separate input (`identity_pool_roles`) so their trust policies can reference `module.cognito.identity_pool_id` without a dependency cycle. Always pin the `cognito-identity.amazonaws.com:aud` condition to the pool ID; without it any identity pool in any account can assume the role.

**Managed login.** With `domain_managed_login_version = 2`, every client that uses the code flow gets a branding style, the Cognito default unless the client sets `managed_login_branding`. Without a style, managed login serves no pages for that client.

**Users.** `users` is for bootstrapping the first administrators. Cognito emails a temporary password, so no password passes through Terraform. Manage the wider user base through federation or the application, not Terraform state.

**Refresh token rotation.** Cognito rejects `ALLOW_REFRESH_TOKEN_AUTH` on a client with rotation enabled, so the module drops that flow when `refresh_token_rotation` is set. Clients then refresh through `GetTokensFromRefreshToken` or the `/oauth2/token` endpoint.

**Log delivery.** `userNotification` logs can only go to CloudWatch Logs; `userAuthEvents` can go to CloudWatch Logs, S3 or Firehose and needs the `PLUS` tier. Cognito adds the delivery policy to the destination when the caller can write it.

**Implicit grant.** `allowed_oauth_flows` accepts `code` and `client_credentials` only. The implicit grant returns tokens in the URL fragment and is rejected by validation.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.13.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.13.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cognito_identity_pool.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_identity_pool) | resource |
| [aws_cognito_identity_pool_roles_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_identity_pool_roles_attachment) | resource |
| [aws_cognito_identity_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_identity_provider) | resource |
| [aws_cognito_log_delivery_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_log_delivery_configuration) | resource |
| [aws_cognito_managed_login_branding.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_managed_login_branding) | resource |
| [aws_cognito_resource_server.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_resource_server) | resource |
| [aws_cognito_risk_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_risk_configuration) | resource |
| [aws_cognito_user.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user) | resource |
| [aws_cognito_user_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_group) | resource |
| [aws_cognito_user_in_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_in_group) | resource |
| [aws_cognito_user_pool.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool) | resource |
| [aws_cognito_user_pool_client.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client) | resource |
| [aws_cognito_user_pool_domain.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_domain) | resource |
| [aws_cognito_user_pool_ui_customization.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_ui_customization) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_recovery_mechanisms"></a> [account\_recovery\_mechanisms](#input\_account\_recovery\_mechanisms) | Account recovery options in priority order: verified\_email, verified\_phone\_number or admin\_only | <pre>list(object({<br/>    name     = string<br/>    priority = number<br/>  }))</pre> | <pre>[<br/>  {<br/>    "name": "verified_email",<br/>    "priority": 1<br/>  }<br/>]</pre> | no |
| <a name="input_advanced_security_custom_auth_mode"></a> [advanced\_security\_custom\_auth\_mode](#input\_advanced\_security\_custom\_auth\_mode) | Threat protection for custom authentication flows: AUDIT or ENFORCED. Needs advanced\_security\_mode | `string` | `null` | no |
| <a name="input_advanced_security_mode"></a> [advanced\_security\_mode](#input\_advanced\_security\_mode) | Threat protection for standard authentication: OFF, AUDIT or ENFORCED. Needs PLUS | `string` | `null` | no |
| <a name="input_alias_attributes"></a> [alias\_attributes](#input\_alias\_attributes) | Attributes that can be used as aliases for the username (email, phone\_number, preferred\_username). Conflicts with username\_attributes. Cannot be changed after creation | `list(string)` | `null` | no |
| <a name="input_allow_admin_create_user_only"></a> [allow\_admin\_create\_user\_only](#input\_allow\_admin\_create\_user\_only) | Allow only administrators to create users. Set to false to enable self sign-up | `bool` | `true` | no |
| <a name="input_allowed_first_auth_factors"></a> [allowed\_first\_auth\_factors](#input\_allowed\_first\_auth\_factors) | Sign-in factors offered in choice-based authentication (PASSWORD, EMAIL\_OTP, SMS\_OTP, WEB\_AUTHN). Needs ESSENTIALS or PLUS | `list(string)` | `null` | no |
| <a name="input_attributes_require_verification_before_update"></a> [attributes\_require\_verification\_before\_update](#input\_attributes\_require\_verification\_before\_update) | Attributes that keep their old value until the new one is verified. Defaults to auto\_verified\_attributes; set to [] to disable | `list(string)` | `null` | no |
| <a name="input_auto_verified_attributes"></a> [auto\_verified\_attributes](#input\_auto\_verified\_attributes) | Attributes Cognito verifies automatically by sending a code (email, phone\_number) | `list(string)` | <pre>[<br/>  "email"<br/>]</pre> | no |
| <a name="input_clients"></a> [clients](#input\_clients) | App clients keyed by client name. Token validity units default to minutes for access and ID tokens and days for refresh tokens. Enabling refresh\_token\_rotation removes ALLOW\_REFRESH\_TOKEN\_AUTH from explicit\_auth\_flows, since Cognito rejects the two together | <pre>map(object({<br/>    generate_secret               = optional(bool, false)<br/>    explicit_auth_flows           = optional(list(string), ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"])<br/>    allowed_oauth_flows           = optional(list(string), [])<br/>    allowed_oauth_scopes          = optional(list(string), [])<br/>    callback_urls                 = optional(list(string), [])<br/>    logout_urls                   = optional(list(string), [])<br/>    default_redirect_uri          = optional(string)<br/>    supported_identity_providers  = optional(list(string), ["COGNITO"])<br/>    read_attributes               = optional(list(string))<br/>    write_attributes              = optional(list(string))<br/>    access_token_validity         = optional(number, 60)<br/>    id_token_validity             = optional(number, 60)<br/>    refresh_token_validity        = optional(number, 30)<br/>    auth_session_validity         = optional(number, 3)<br/>    enable_token_revocation       = optional(bool, true)<br/>    prevent_user_existence_errors = optional(string, "ENABLED")<br/>    token_validity_units = optional(object({<br/>      access_token  = optional(string, "minutes")<br/>      id_token      = optional(string, "minutes")<br/>      refresh_token = optional(string, "days")<br/>    }), {})<br/>    enable_propagate_additional_user_context_data = optional(bool, false)<br/>    refresh_token_rotation = optional(object({<br/>      enabled                    = optional(bool, true)<br/>      retry_grace_period_seconds = optional(number)<br/>    }))<br/>    managed_login_branding = optional(object({<br/>      settings = optional(string)<br/>      assets = optional(list(object({<br/>        category   = string<br/>        color_mode = string<br/>        extension  = string<br/>        bytes      = string<br/>      })), [])<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Block deletion of the user pool. Must be set to false and applied before the pool can be destroyed | `bool` | `true` | no |
| <a name="input_device_configuration"></a> [device\_configuration](#input\_device\_configuration) | Device tracking settings. Remembered devices can skip MFA, so leave unset unless that is intended | <pre>object({<br/>    challenge_required_on_new_device      = optional(bool, true)<br/>    device_only_remembered_on_user_prompt = optional(bool, true)<br/>  })</pre> | `null` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain prefix (for <prefix>.auth.<region>.amazoncognito.com) or a fully qualified custom domain. A custom domain also needs domain\_certificate\_arn | `string` | `null` | no |
| <a name="input_domain_certificate_arn"></a> [domain\_certificate\_arn](#input\_domain\_certificate\_arn) | ACM certificate ARN for a custom domain. The certificate must be in us-east-1 | `string` | `null` | no |
| <a name="input_domain_managed_login_version"></a> [domain\_managed\_login\_version](#input\_domain\_managed\_login\_version) | 1 for the classic hosted UI, 2 for managed login. With 2, every client using the code flow gets a branding style, the Cognito default unless managed\_login\_branding is set on the client | `number` | `null` | no |
| <a name="input_email_configuration"></a> [email\_configuration](#input\_email\_configuration) | Email sending settings. Without this Cognito sends from its own address with a low daily quota, which is not suitable for production | <pre>object({<br/>    email_sending_account  = optional(string, "DEVELOPER")<br/>    source_arn             = optional(string)<br/>    from_email_address     = optional(string)<br/>    reply_to_email_address = optional(string)<br/>    configuration_set      = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_email_mfa_configuration"></a> [email\_mfa\_configuration](#input\_email\_mfa\_configuration) | Enables email MFA with the given message. Needs ESSENTIALS or PLUS and email\_configuration with DEVELOPER sending. The message must contain {####} | <pre>object({<br/>    subject = optional(string)<br/>    message = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_hosted_ui_customization"></a> [hosted\_ui\_customization](#input\_hosted\_ui\_customization) | CSS and logo for the classic hosted UI (domain\_managed\_login\_version 1), applied to every client. image\_file is the base64 encoded logo | <pre>object({<br/>    css        = optional(string)<br/>    image_file = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_identity_pool"></a> [identity\_pool](#input\_identity\_pool) | Identity pool that exchanges sign-ins for AWS credentials. Not created when null. clients lists names from var.clients allowed to use the pool | <pre>object({<br/>    name                             = optional(string)<br/>    allow_unauthenticated_identities = optional(bool, false)<br/>    allow_classic_flow               = optional(bool, false)<br/>    clients                          = optional(list(string), [])<br/>    server_side_token_check          = optional(bool, true)<br/>    supported_login_providers        = optional(map(string))<br/>    openid_connect_provider_arns     = optional(list(string))<br/>    saml_provider_arns               = optional(list(string))<br/>    developer_provider_name          = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_identity_pool_roles"></a> [identity\_pool\_roles](#input\_identity\_pool\_roles) | IAM roles for the identity pool. Kept apart from identity\_pool so the roles can trust the pool through the cognito-identity.amazonaws.com:aud condition on identity\_pool\_id without a cycle. role\_mappings is keyed by a client name from var.clients; Token reads the cognito:preferred\_role claim from group membership, Rules matches claims in order. | <pre>object({<br/>    authenticated_role_arn   = string<br/>    unauthenticated_role_arn = optional(string)<br/>    role_mappings = optional(map(object({<br/>      type                      = string<br/>      ambiguous_role_resolution = optional(string, "Deny")<br/>      rules = optional(list(object({<br/>        claim      = string<br/>        match_type = string<br/>        value      = string<br/>        role_arn   = string<br/>      })), [])<br/>    })), {})<br/>  })</pre> | `null` | no |
| <a name="input_identity_provider_client_secrets"></a> [identity\_provider\_client\_secrets](#input\_identity\_provider\_client\_secrets) | Client secrets for identity providers, keyed by provider name. Merged into provider\_details as client\_secret | `map(string)` | `{}` | no |
| <a name="input_identity_providers"></a> [identity\_providers](#input\_identity\_providers) | Federated identity providers keyed by provider name. Put OIDC and social client secrets in identity\_provider\_client\_secrets instead of provider\_details | <pre>map(object({<br/>    provider_type     = string<br/>    provider_details  = map(string)<br/>    attribute_mapping = optional(map(string))<br/>    idp_identifiers   = optional(list(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_invite_message_template"></a> [invite\_message\_template](#input\_invite\_message\_template) | Invitation message sent to users created by an administrator. Messages must contain {username} and {####} | <pre>object({<br/>    email_subject = optional(string)<br/>    email_message = optional(string)<br/>    sms_message   = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_lambda_config"></a> [lambda\_config](#input\_lambda\_config) | Lambda triggers. Each function needs an aws\_lambda\_permission allowing cognito-idp.amazonaws.com with the user pool ARN as source\_arn | <pre>object({<br/>    create_auth_challenge          = optional(string)<br/>    custom_message                 = optional(string)<br/>    define_auth_challenge          = optional(string)<br/>    post_authentication            = optional(string)<br/>    post_confirmation              = optional(string)<br/>    pre_authentication             = optional(string)<br/>    pre_sign_up                    = optional(string)<br/>    user_migration                 = optional(string)<br/>    verify_auth_challenge_response = optional(string)<br/>    kms_key_id                     = optional(string)<br/>    pre_token_generation_config = optional(object({<br/>      lambda_arn     = string<br/>      lambda_version = optional(string, "V2_0")<br/>    }))<br/>    custom_email_sender = optional(object({<br/>      lambda_arn     = string<br/>      lambda_version = optional(string, "V1_0")<br/>    }))<br/>    custom_sms_sender = optional(object({<br/>      lambda_arn     = string<br/>      lambda_version = optional(string, "V1_0")<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_log_delivery"></a> [log\_delivery](#input\_log\_delivery) | Exports user pool logs. userNotification at ERROR covers message delivery failures on any tier; userAuthEvents at INFO records sign-in activity and needs PLUS. Set exactly one destination per entry | <pre>list(object({<br/>    event_source             = string<br/>    log_level                = string<br/>    cloudwatch_log_group_arn = optional(string)<br/>    firehose_stream_arn      = optional(string)<br/>    s3_bucket_arn            = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_mfa_configuration"></a> [mfa\_configuration](#input\_mfa\_configuration) | MFA enforcement: OFF, ON or OPTIONAL | `string` | `"ON"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the user pool. Also used as the default identity pool name | `string` | n/a | yes |
| <a name="input_password_policy"></a> [password\_policy](#input\_password\_policy) | Password policy for the user pool | <pre>object({<br/>    minimum_length                   = optional(number, 14)<br/>    require_lowercase                = optional(bool, true)<br/>    require_uppercase                = optional(bool, true)<br/>    require_numbers                  = optional(bool, true)<br/>    require_symbols                  = optional(bool, true)<br/>    temporary_password_validity_days = optional(number, 3)<br/>    password_history_size            = optional(number)<br/>  })</pre> | `{}` | no |
| <a name="input_region"></a> [region](#input\_region) | Region to manage the resources in. Defaults to the provider region | `string` | `null` | no |
| <a name="input_resource_servers"></a> [resource\_servers](#input\_resource\_servers) | OAuth resource servers keyed by identifier, usually the API URL. scopes maps scope name to description | <pre>map(object({<br/>    name   = optional(string)<br/>    scopes = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_risk_configuration"></a> [risk\_configuration](#input\_risk\_configuration) | Threat protection responses for the whole pool. Needs PLUS and advanced\_security\_mode = ENFORCED. Event actions are BLOCK, MFA\_IF\_CONFIGURED, MFA\_REQUIRED or NO\_ACTION. notify needs notify\_configuration with a verified SES identity | <pre>object({<br/>    compromised_credentials_action       = optional(string, "BLOCK")<br/>    compromised_credentials_event_filter = optional(list(string), ["SIGN_IN", "PASSWORD_CHANGE", "SIGN_UP"])<br/>    account_takeover = optional(object({<br/>      low_action = optional(object({<br/>        event_action = string<br/>        notify       = optional(bool, false)<br/>      }), { event_action = "NO_ACTION" })<br/>      medium_action = optional(object({<br/>        event_action = string<br/>        notify       = optional(bool, false)<br/>      }), { event_action = "MFA_IF_CONFIGURED" })<br/>      high_action = optional(object({<br/>        event_action = string<br/>        notify       = optional(bool, false)<br/>      }), { event_action = "BLOCK" })<br/>      notify_configuration = optional(object({<br/>        source_arn = string<br/>        from       = optional(string)<br/>        reply_to   = optional(string)<br/>      }))<br/>    }), {})<br/>    blocked_ip_ranges = optional(list(string))<br/>    skipped_ip_ranges = optional(list(string))<br/>  })</pre> | `null` | no |
| <a name="input_schema_attributes"></a> [schema\_attributes](#input\_schema\_attributes) | Custom attributes. Attributes can be added later but not changed or removed | <pre>list(object({<br/>    name                     = string<br/>    attribute_data_type      = string<br/>    mutable                  = optional(bool, true)<br/>    required                 = optional(bool, false)<br/>    developer_only_attribute = optional(bool, false)<br/>    string_attribute_constraints = optional(object({<br/>      min_length = optional(string)<br/>      max_length = optional(string)<br/>    }))<br/>    number_attribute_constraints = optional(object({<br/>      min_value = optional(string)<br/>      max_value = optional(string)<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_sms_authentication_message"></a> [sms\_authentication\_message](#input\_sms\_authentication\_message) | SMS MFA message. Must contain {####} | `string` | `null` | no |
| <a name="input_sms_configuration"></a> [sms\_configuration](#input\_sms\_configuration) | SNS settings for SMS messages. The role must trust cognito-idp.amazonaws.com with the given external ID | <pre>object({<br/>    external_id    = string<br/>    sns_caller_arn = string<br/>    sns_region     = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_software_token_mfa_enabled"></a> [software\_token\_mfa\_enabled](#input\_software\_token\_mfa\_enabled) | Allow authenticator app (TOTP) MFA. Ignored when mfa\_configuration is OFF | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the user pool and identity pool | `map(string)` | `{}` | no |
| <a name="input_user_groups"></a> [user\_groups](#input\_user\_groups) | User groups keyed by group name. Lower precedence wins when a user is in several groups with roles | <pre>map(object({<br/>    description = optional(string)<br/>    precedence  = optional(number)<br/>    role_arn    = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_user_pool_tier"></a> [user\_pool\_tier](#input\_user\_pool\_tier) | Feature plan of the user pool: LITE, ESSENTIALS or PLUS. Threat protection (advanced\_security\_mode) needs PLUS | `string` | `"ESSENTIALS"` | no |
| <a name="input_username_attributes"></a> [username\_attributes](#input\_username\_attributes) | Attributes users sign in with instead of a username (email, phone\_number). Conflicts with alias\_attributes. Cannot be changed after creation | `list(string)` | <pre>[<br/>  "email"<br/>]</pre> | no |
| <a name="input_username_case_sensitive"></a> [username\_case\_sensitive](#input\_username\_case\_sensitive) | Whether usernames and aliases are case sensitive. Cannot be changed after creation | `bool` | `false` | no |
| <a name="input_users"></a> [users](#input\_users) | Users to bootstrap, keyed by username. Cognito delivers a temporary password, so no password passes through Terraform. Meant for initial administrators, not for managing the user base | <pre>map(object({<br/>    attributes               = optional(map(string), {})<br/>    groups                   = optional(list(string), [])<br/>    desired_delivery_mediums = optional(list(string), ["EMAIL"])<br/>    enabled                  = optional(bool, true)<br/>    message_action           = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_verification_message_template"></a> [verification\_message\_template](#input\_verification\_message\_template) | Messages sent to verify email addresses and phone numbers | <pre>object({<br/>    default_email_option  = optional(string)<br/>    email_subject         = optional(string)<br/>    email_message         = optional(string)<br/>    email_subject_by_link = optional(string)<br/>    email_message_by_link = optional(string)<br/>    sms_message           = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_web_authn_configuration"></a> [web\_authn\_configuration](#input\_web\_authn\_configuration) | Passkey settings. relying\_party\_id defaults to the user pool domain | <pre>object({<br/>    relying_party_id  = optional(string)<br/>    user_verification = optional(string, "required")<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_client_ids"></a> [client\_ids](#output\_client\_ids) | App client IDs keyed by client name |
| <a name="output_client_secrets"></a> [client\_secrets](#output\_client\_secrets) | App client secrets keyed by client name, for clients created with generate\_secret |
| <a name="output_domain"></a> [domain](#output\_domain) | Domain prefix or custom domain of the user pool, or null when not created |
| <a name="output_domain_cloudfront_distribution"></a> [domain\_cloudfront\_distribution](#output\_domain\_cloudfront\_distribution) | CloudFront distribution to alias a custom domain to, or null when no domain is created |
| <a name="output_domain_cloudfront_distribution_zone_id"></a> [domain\_cloudfront\_distribution\_zone\_id](#output\_domain\_cloudfront\_distribution\_zone\_id) | Route 53 hosted zone ID of the CloudFront distribution, or null when no domain is created |
| <a name="output_domain_url"></a> [domain\_url](#output\_domain\_url) | Base URL of the managed login and OAuth endpoints, or null when no domain is created |
| <a name="output_identity_pool_arn"></a> [identity\_pool\_arn](#output\_identity\_pool\_arn) | ARN of the identity pool, or null when not created |
| <a name="output_identity_pool_id"></a> [identity\_pool\_id](#output\_identity\_pool\_id) | ID of the identity pool, or null when not created |
| <a name="output_identity_provider_names"></a> [identity\_provider\_names](#output\_identity\_provider\_names) | Names of the federated identity providers, for use in supported\_identity\_providers |
| <a name="output_managed_login_branding_ids"></a> [managed\_login\_branding\_ids](#output\_managed\_login\_branding\_ids) | Managed login branding style IDs keyed by client name |
| <a name="output_resource_server_scope_identifiers"></a> [resource\_server\_scope\_identifiers](#output\_resource\_server\_scope\_identifiers) | Fully qualified scope names (<identifier>/<scope>) keyed by resource server identifier |
| <a name="output_user_group_names"></a> [user\_group\_names](#output\_user\_group\_names) | Names of the user groups |
| <a name="output_user_pool_arn"></a> [user\_pool\_arn](#output\_user\_pool\_arn) | ARN of the user pool |
| <a name="output_user_pool_endpoint"></a> [user\_pool\_endpoint](#output\_user\_pool\_endpoint) | Endpoint of the user pool, also the provider name used by identity pools |
| <a name="output_user_pool_id"></a> [user\_pool\_id](#output\_user\_pool\_id) | ID of the user pool |
| <a name="output_user_pool_issuer_url"></a> [user\_pool\_issuer\_url](#output\_user\_pool\_issuer\_url) | OIDC issuer URL. Tokens carry this value in the iss claim |
| <a name="output_user_pool_jwks_uri"></a> [user\_pool\_jwks\_uri](#output\_user\_pool\_jwks\_uri) | URL of the JSON Web Key Set used to verify token signatures |
| <a name="output_user_pool_name"></a> [user\_pool\_name](#output\_user\_pool\_name) | Name of the user pool |
<!-- END_TF_DOCS -->
