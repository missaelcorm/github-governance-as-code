# GitHub governance as code

Reference repository for the talk **"GitHub governance as code: from
click-ops to custom properties + org rulesets."** Everything here is real,
apply-able Terraform (against `integrations/github`), not pseudocode —
it's meant to keep working as a resource after the talk, not just during
the 30 minutes on stage.

## How this maps to the talk

| Talk section | Where |
|---|---|
| Setup — create the repo everything else governs | [`00-setup/`](./00-setup) |
| 1–2. The problem, why IaC | (no code — see slides) |
| 3. Teams, roles, permissions | [`01-teams-and-permissions/`](./01-teams-and-permissions) |
| 4. Branch protection → rulesets | [`02-repository-ruleset/`](./02-repository-ruleset) |
| 5. Custom properties + org rulesets (**the main pattern**, incl. live demo) | [`03-classification-and-org-rulesets/`](./03-classification-and-org-rulesets) |
| 6. Operational realities | [`docs/operational-realities.md`](./docs/operational-realities.md) |
| Live demo scripts | [`scripts/`](./scripts) |
| Interactive version of the whole demo, in a browser | [`notebooks/`](./notebooks) |
| What your GitHub plan does and doesn't allow | [`docs/plan-requirements.md`](./docs/plan-requirements.md) |

Each numbered directory is its own Terraform root module with its own
state — see `docs/operational-realities.md` for why they're split this
way rather than living in one big apply.

## Prerequisites

- **A GitHub organization.** Modules `00`, `01` and `02` run on a free
  org. Module `03` — the core pattern — needs **GitHub Team** (or
  Enterprise Cloud), because organization rulesets can't be created on a
  free plan. See [`docs/plan-requirements.md`](./docs/plan-requirements.md)
  for the full matrix.
- Terraform >= 1.7
- `integrations/github` provider ~> 6.0
- Org owner access, or a GitHub App installation with the equivalent
  permissions, for initial apply
- [GitHub CLI](https://cli.github.com/) (`gh`), for the live-demo scripts

### What your plan changes

**Organization rulesets need GitHub Team.** On free, module `03` fails with
`403 Upgrade to GitHub Team to enable this feature`. Organization **custom
properties** do work on free, so the classification layer is available
there — it's only the org rulesets that consume those values that are
gated.

**On free, rulesets only apply to public repos.** A ruleset on a private
repo applies successfully, shows up in the API, and protects nothing, with
no error. Keep the demo repos public.

Three things this repo deliberately doesn't use because they're
Enterprise Cloud only: custom repository roles, the *restrict commit
metadata* rules, and the *restrict branch names* rule.
[`docs/plan-requirements.md`](./docs/plan-requirements.md) covers what to
reach for instead.

## Authentication

The provider blocks in every module read credentials from the
environment — nothing is hardcoded:

```bash
# Option A: Personal Access Token (fine for local iteration)
export GITHUB_TOKEN="ghp_..."

# Option B: GitHub App (recommended for CI/CD — see docs/operational-realities.md)
export GITHUB_APP_ID="..."
export GITHUB_APP_INSTALLATION_ID="..."
export GITHUB_APP_PEM_FILE="/path/to/private-key.pem"
```

A classic PAT needs `repo` and `admin:org`. Add `workflow` if you want
`00-setup` to commit the CI workflow file, and `delete_repo` if you want
to `terraform destroy` the demo repo later. Both are explained in
[`00-setup/README.md`](./00-setup/README.md).

## Set your variables once

Every module takes the same handful of inputs. Exporting them as
`TF_VAR_*` means Terraform picks them up in all four modules and you
never create a `terraform.tfvars` at all — which also means nothing
org-specific can end up in a file you accidentally commit:

```bash
export GITHUB_TOKEN="ghp_..."

export TF_VAR_github_organization="my-org"
export TF_VAR_repository_name="payments-service"
export TF_VAR_bypass_team_slug="security"

# Convenience for the scripts/ helpers, which take <org>/<repo>:
export DEMO_REPO="${TF_VAR_github_organization}/${TF_VAR_repository_name}"
```

`terraform.tfvars.example` is in each module if you'd rather commit your
inputs to a file and review them in a PR, which is the better answer for
anything real.

## Quick start

With the exports above in place, no module needs a `terraform.tfvars`:

```bash
# The repo everything else governs. Public, by default and on purpose.
cd 00-setup
terraform init && terraform apply

# Teams — including the one the rulesets below grant bypass to, which is
# why this has to come before them.
cd ../01-teams-and-permissions
terraform init && terraform apply

# One repo-level ruleset: the version that works but doesn't scale.
cd ../02-repository-ruleset
terraform init && terraform apply

# The pattern the talk is about: classify, then target by classification.
cd ../03-classification-and-org-rulesets
terraform init && terraform apply
```

Order matters in exactly one place: `01` creates the team that `02` and
`03` resolve by slug for their bypass actors, so a team that doesn't
exist yet fails at plan time with `Not Found`. Everything else is
independent.

## Running the live demo yourself

Apply the modules, then do two things in the GitHub UI and ask what changed.

```bash
cd scripts
./show-rules.sh "$DEMO_REPO"      # tier = standard, a short rule list
```

**1. Open a pull request.** On the repo: `README.md` → pencil → add a line →
*Commit changes…* → **Create a new branch and start a pull request**. The
merge box asks for one approval.

**2. Reclassify the repo.** Repo **Settings → Custom properties** → set
`tier` to `regulated` → save.

```bash
./show-rules.sh "$DEMO_REPO"      # more rules now
```

Reload the pull request: same PR, nobody pushed to it, no `terraform apply`
in between — and it now wants two approvals, a code owner, and three checks.
The rules changed because the repository's classification changed, and the
ruleset that did it has never heard of this repo by name.

[`scripts/README.md`](./scripts) has the detail, including the two `gh`
one-liners if you'd rather not click. `notebooks/` runs the same thing in
Google Colab.

## A note on provider schema

Custom-property support in `integrations/github` is comparatively new and
its resource/attribute names have moved across minor versions while the
feature stabilized. Note in particular that the org-level resource is
`github_organization_custom_properties` — **plural** — while the
repo-level one is `github_repository_custom_property`, singular, and
takes `property_value` rather than `property_values`. The files here are
validated against provider **6.13.0**.

Before applying `03-classification-and-org-rulesets` against a real org,
check `properties.tf`'s schema against the
[provider's registry docs](https://registry.terraform.io/providers/integrations/github/latest/docs)
for whatever version you've pinned in `providers.tf`, or just run
`terraform validate`.

## License

MIT — see [`LICENSE`](./LICENSE).
