# sudo-terraform-module-template
A foundational template for creating reusable Terraform modules with best practices, pre-configured files, and workflows.

```plaintext
sudo-terraform-module-template/
├── .claude/
│   ├── CLAUDE.md                  # AI assistant context (single source of truth)
│   └── skills/
│       └── terraform/
│           └── SKILL.md           # Terraform module conventions & rules
├── .github/
│   └── workflows/
│       └── main.yml               # CI pipeline - pre-commit and checkov jobs
├── scripts/
│   └── hooks/
│       └── pre-push-protect-branches.sh  # Rejects pushes to main/master
├── examples/
│   ├── complete/                  # Full-featured usage example
│   └── minimal/                   # Minimal working example
├── AGENTS.md -> .claude/CLAUDE.md # Symlink for AGENTS.md-aware tools
├── CLAUDE.md -> .claude/CLAUDE.md # Symlink for Claude Code auto-discovery
├── .gitignore                     # Terraform, IDE, and OS ignores
├── .pre-commit-config.yaml        # Conventional commits, fmt, tflint, branch protection
├── .tflint.hcl                    # TFLint rule configuration
├── checkov.yaml                   # Checkov security scan config
├── LICENSE                        # License file
├── main.tf                        # Primary module resources
├── Makefile                       # Developer shortcuts: fmt, lint, checkov, docs, validate
├── outputs.tf                     # Module output values
├── README.md                      # Project documentation (this file)
├── variables.tf                   # Module input variables
└── versions.tf                    # Terraform and provider version constraints
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->
