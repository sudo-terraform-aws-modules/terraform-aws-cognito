provider "aws" {
  region = var.region
}

data "aws_partition" "current" {}

locals {
  name    = "example-complete"
  app_url = "https://app.example.com"
  api_id  = "https://api.example.com"
}

module "cognito" {
  source = "../../"

  name = local.name

  # Lets the example be destroyed; keep the default of true for real pools
  deletion_protection = false

  user_pool_tier = "ESSENTIALS"
  domain         = local.name

  password_policy = {
    minimum_length        = 16
    password_history_size = 5
  }

  schema_attributes = [
    {
      name                = "tenant_id"
      attribute_data_type = "String"
      mutable             = false
      string_attribute_constraints = {
        min_length = "1"
        max_length = "64"
      }
    }
  ]

  identity_providers = {
    EntraID = {
      provider_type = "OIDC"
      provider_details = {
        client_id                 = var.entra_client_id
        oidc_issuer               = "https://login.microsoftonline.com/${var.entra_tenant_id}/v2.0"
        authorize_scopes          = "openid email profile"
        attributes_request_method = "GET"
      }
      attribute_mapping = {
        email    = "email"
        name     = "name"
        username = "sub"
      }
    }
  }

  identity_provider_client_secrets = {
    EntraID = var.entra_client_secret
  }

  resource_servers = {
    (local.api_id) = {
      name = "orders-api"
      scopes = {
        "orders.read"  = "Read orders"
        "orders.write" = "Create and update orders"
      }
    }
  }

  clients = {
    web = {
      generate_secret              = true
      allowed_oauth_flows          = ["code"]
      allowed_oauth_scopes         = ["openid", "email", "profile", "${local.api_id}/orders.read"]
      callback_urls                = ["${local.app_url}/auth/callback"]
      logout_urls                  = [local.app_url]
      supported_identity_providers = ["COGNITO", "EntraID"]
      refresh_token_rotation = {
        retry_grace_period_seconds = 10
      }
    }

    orders-worker = {
      generate_secret       = true
      explicit_auth_flows   = []
      allowed_oauth_flows   = ["client_credentials"]
      allowed_oauth_scopes  = ["${local.api_id}/orders.read", "${local.api_id}/orders.write"]
      access_token_validity = 15
    }

    mobile = {
      explicit_auth_flows = ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
    }
  }

  user_groups = {
    admin = {
      description = "Full administrative access"
      precedence  = 1
      role_arn    = aws_iam_role.admin.arn
    }
    support = {
      description = "Read-only support access"
      precedence  = 10
    }
  }

  users = {
    "admin@example.com" = {
      attributes = {
        email          = "admin@example.com"
        email_verified = "true"
      }
      groups = ["admin"]
    }
  }

  identity_pool = {
    clients = ["mobile"]
  }

  identity_pool_roles = {
    authenticated_role_arn = aws_iam_role.authenticated.arn
    role_mappings = {
      mobile = {
        type = "Token"
      }
    }
  }

  tags = {
    Environment = "DEV"
  }
}

# Both roles trust only this identity pool and only authenticated identities

data "aws_iam_policy_document" "identity_pool_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values   = [module.cognito.identity_pool_id]
    }

    condition {
      test     = "ForAnyValue:StringLike"
      variable = "cognito-identity.amazonaws.com:amr"
      values   = ["authenticated"]
    }
  }
}

resource "aws_iam_role" "authenticated" {
  name               = "${local.name}-authenticated"
  assume_role_policy = data.aws_iam_policy_document.identity_pool_trust.json
}

resource "aws_iam_role" "admin" {
  name               = "${local.name}-admin"
  assume_role_policy = data.aws_iam_policy_document.identity_pool_trust.json
}

resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.admin.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/ReadOnlyAccess"
}
