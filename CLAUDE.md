# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this repo is

Reference/demo repo for a 30-minute conference talk on GitHub governance
as code (Terraform + `integrations/github`). It has two jobs: be a working
live-demo environment, and remain a correct standalone reference people
clone afterwards.

**It is teaching material.** Favour less code that reads clearly over more
code that covers more cases. When a step can be a documented click in the
GitHub UI or a one-line `gh` command instead of a script, prefer that —
that's why `scripts/` holds one script and not four.

## Layout

Four **independent Terraform root modules**, each its own state, split by
change frequency/blast-radius (`docs/operational-realities.md` §2), not by
resource type:

- `00-setup/` — creates the one disposable demo repository everything else
  governs. Not part of the talk. The only module that creates a
  repository; keep it that way.
- `01-teams-and-permissions/` — teams, membership, repo access grants
- `02-repository-ruleset/` — a single-repo ruleset, the "doesn't scale"
  example, intentionally. Deliberately a **modest** baseline: 1 approval,
  no linear history, no signed commits, no code-owner review. Don't
  tighten it. Rules aggregate across all matching rulesets and the
  strictest wins, so a strict ruleset here masks module `03`'s tiers
  entirely and reclassifying a repo appears to do nothing — which is the
  demo's whole payoff.
- `03-classification-and-org-rulesets/` — **the core pattern**: org
  custom-property schema (`properties.tf`) + org rulesets targeting repos
  by those properties (`rulesets.tf`) + a commented-out example of setting
  property values from Terraform (`repo_properties.tf`)

**Apply order**: `00` before `02`/`03` (they need a repo to target), and
`01` before them too (they resolve their bypass team by slug, so a missing
team fails at plan time). Otherwise independent — don't merge the states.

`docs/`, `scripts/` and `notebooks/` are talk-support material, not
Terraform.

## The demo flow

Terraform does setup. The demo itself is **two actions in the GitHub UI** —
open a PR by editing `README.md`, then set `tier = regulated` under repo
Settings → Custom properties — with `scripts/show-rules.sh` before and
after to show the rule list change. Keep it that way; don't reintroduce
scripts that automate the clicking.

`notebooks/github-governance-demo.ipynb` is the Colab version. Its cells
are **`%%bash`, deliberately** — the same commands a terminal user runs.
There is exactly one Python cell, reading `GITHUB_TOKEN` from Colab
Secrets, because `%%bash` can't reach that API. Don't add Python wrappers,
`subprocess`, or direct REST calls. Cross-cell state lives in
`/content/env.sh`, sourced at the top of every later cell, because each
`%%bash` cell is its own shell.

## Conventions

- Run `terraform fmt -recursive` before committing any `.tf` change.
- Comments explain the **GitHub-specific gotcha**, not the HCL. Keep them
  short. Three that matter most:
  - In `rules {}`, `deletion = true` / `non_fast_forward = true` mean that
    action is **restricted**, not permitted. Easy to misread.
  - The two org rulesets in `03` are **additive** — GitHub merges every
    ruleset matching a ref and takes the most restrictive value per rule.
    Not mutually exclusive alternatives.
  - A required status check that never reports blocks a PR on "Expected"
    forever instead of failing it. Changing a required context in `02`/`03`
    means changing the matching job `name:` in `00-setup`'s CI workflow.
  - The rules API reports a ruleset's `ruleset_source` as the org or repo
    that owns it, **not** the ruleset's name. `scripts/show-rules.sh` has
    to look names up by `ruleset_id` or its output can't distinguish the
    baseline tier from the regulated one.
  - A CODEOWNERS entry needs the named team to exist **and** to have write
    access to the repo. Missing either, GitHub reports the entry as invalid
    (`/repos/{owner}/{repo}/codeowners/errors`) and
    `require_code_owner_review` is never satisfiable. The file itself can be
    committed before any of that is true — it's just a file, so `00-setup`
    writes it in one pass and it starts working once `01` has run.
- **Plan requirements, verified against a real free org:** modules `00`,
  `01` and `02` apply on free. Module `03` does not — org rulesets return
  `403 Upgrade to GitHub Team to enable this feature`. Org **custom
  properties** (`properties.tf`) *do* work on free, so the line falls
  between classification and enforcement, not around module `03` as a
  whole. Keep that distinction; it's the useful part.
- Also keep documented: on free, rulesets only apply to **public** repos.
  Unlike the 403, that one fails silently — clean plan, ruleset present,
  nothing protected.
- Don't trust the GitHub UI about what a plan allows; it let us create an
  org ruleset on free that the API refuses. Verify with `terraform apply`
  before documenting a plan claim.
- Don't introduce Enterprise-Cloud-only features: custom repository roles,
  the *restrict commit metadata* rules, *restrict branch names*,
  `enforcement = "evaluate"`. `docs/plan-requirements.md` is the single
  source of truth for plan claims — don't state one anywhere without it
  agreeing.
- Bypass actors are resolved by **team slug** via a `github_team` data
  source (`data.tf` in `02` and `03`), never by numeric ID in a variable.
  `actor_id` is typed as a number and the data source returns `id` as a
  string, so the `tonumber()` is load-bearing. Keep `summary_only = true`
  or the lookup pulls every member and repo of the team on every plan.
- The README documents `TF_VAR_*` exports as the primary way to pass
  variables, so one set covers all four modules. Terraform silently
  ignores a `TF_VAR_` for a variable a module doesn't declare — that's what
  makes it work; don't add unused variables to "fix" it.
  `01-teams-and-permissions` is the exception: `teams` is a map of objects,
  so it wants a `terraform.tfvars`.
- `properties.tf` touches a newer corner of the provider. The org resource
  is `github_organization_custom_properties` (**plural**); the repo one is
  `github_repository_custom_property` (singular, takes `property_value`).
  Check changes against the registry docs for the pinned version, not from
  memory.
- Never put a real token, org name, or repo name in a committed file.
  `terraform.tfvars` is gitignored; only `*.tfvars.example` is tracked.
  `payments-service` / `my-org` are placeholders.

## Common commands

```bash
# Variables, once, for every module:
export GITHUB_TOKEN="..."
export TF_VAR_github_organization="my-org"
export TF_VAR_repository_name="payments-service"
export TF_VAR_bypass_team_slug="security"

# Per module, in order (00 -> 01 -> 02/03):
cd 0N-*/
terraform init && terraform plan && terraform apply

# Demo helper (needs `gh` authenticated):
./scripts/show-rules.sh <org>/<repo>
```

## When extending this repo

- New governance rule → ask "does this change per-repo or
  per-classification?" to decide the module. Per-repo one-offs don't
  belong here at all (that's what `02` demonstrates you shouldn't scale).
- Check a new rule or resource's plan requirement before adding it, and
  reflect it in `docs/plan-requirements.md`.
- Keep `docs/`, `notebooks/` and each module's `README.md` in sync with
  code changes — this repo is documentation as much as infrastructure.
