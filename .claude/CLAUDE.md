# CLAUDE.md

Project-scoped context for Claude Code and AGENTS.md-aware runtimes (Codex, Kiro, GitLab Duo, etc.). Claude Code reads this file from `.claude/` directly; the root `AGENTS.md` symlink points here for the other runtimes.

## What this repository is

A Terraform module for Amazon Cognito, generated from [sudo-terraform-module-template](https://github.com/sudo-terraform-aws-modules/sudo-terraform-module-template) and maintained by SUDO Consultants. It manages a user pool (`aws_cognito_user_pool.this`) and the resources around it: domain, app clients, resource servers, groups, identity providers, bootstrap users, managed login branding, threat protection, log delivery and an optional identity pool.

## Module specifics

- The AWS provider floor is `>= 6.13.0` because managed login branding arrived in 6.12.0 and its multi-client read fix in 6.13.0. Raising it again is a breaking change.
- `clients`, `user_groups`, `users`, `resource_servers` and `identity_providers` are maps whose keys are the resource identity. Renaming a key replaces the resource (a new client ID, a deleted group or user), so treat key renames as breaking.
- Identity pool roles live in `identity_pool_roles`, separate from `identity_pool`, so role trust policies can reference `identity_pool_id` without a cycle. Keep them separate.
- Behaviour that came out of live testing and must not regress: clients with refresh token rotation drop `ALLOW_REFRESH_TOKEN_AUTH` (Cognito rejects the pair), OIDC providers default `attributes_url_add_attributes = "false"` (Cognito adds it on read), empty OAuth lists are sent as `[]` so removed callback URLs are cleared, and `use_cognito_provided_values` is `null` rather than `false` when branding settings are given.
- Unit tests in `tests/unit.tftest.hcl` use a mock provider and cover these behaviours plus the input validations. Add a test with every behaviour change.

## Git workflow (non-negotiable)

- Never commit to `main` or `master`. Create a feature branch for every task. Local guards: `no-commit-to-branch` (commit time) and the pre-push hook in `scripts/hooks/` (push time).
- Commit messages follow Conventional Commits. Allowed types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`, `perf`, `build`, `revert`. The commit-msg hook rejects anything else.
- Do not amend or force-push shared branches; add new commits instead.
- Never edit files under `.terraform/` or commit `*.tfstate` or `.terraform.lock.hcl`.

## How to validate (run before declaring work done)

```text
make fmt        # terraform fmt -recursive
make lint       # tflint --config=.tflint.hcl
make checkov    # checkov security scan
make validate   # terraform init -backend=false && terraform validate
make docs       # regenerate README terraform-docs section (do not hand-edit it)
make test       # unit tests against a mock provider (Terraform 1.7+)
make pre-commit # all pre-commit hooks against all files
```

The README's Requirements/Providers/Inputs/Outputs tables between the `BEGIN_TF_DOCS`/`END_TF_DOCS` markers are generated. Change `variables.tf` / `outputs.tf` and run `make docs` instead of editing them.

## Contributing checklist

1. Branch from `main`.
2. Make the change; update or add `examples/` when the module API changes.
3. `make fmt lint checkov test` clean, `make docs` regenerated, `CHANGELOG.md` updated.
4. Conventional commit message.
5. Open a PR; CI runs pre-commit, checkov and the unit tests, and all must pass.

## Terraform conventions

All module conventions, version-floor guards, HCL patterns, security rules, testing strategy, and semver discipline live in `.claude/skills/terraform/SKILL.md`.

Load it (or let Claude Code auto-discover it) before writing or reviewing any Terraform in this repository.
