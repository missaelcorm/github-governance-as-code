# 03 — Custom properties + organization rulesets

Maps to **talk section 5 — the main pattern**. This is the module the
whole talk builds up to.

## The idea

1. `properties.tf` defines a small **classification schema** at the org
   level: `tier`, `compliance_framework`, `owning_team`.
2. `rulesets.tf` defines **org-level rulesets whose conditions match on
   those properties**, not on repo names.
3. Any repo that ends up with `tier = regulated` — set any way at all —
   inherits `regulated_repo_protection` the moment that value lands.
   Nothing in this repository needs to change, and nothing in *this
   Terraform state* needs to change either.

That last point is the payoff: classification and enforcement are
decoupled. Onboarding a new regulated repo is a one-line property change,
not a new Terraform module.

## What you need to run this

A GitHub organization on **any plan, including free**. Both halves of
this module apply successfully on a free org: custom properties are a
free-plan feature, and org rulesets can be created and targeted on free
too.

The one thing free doesn't give you is **enforcement** of those org
rulesets — that's GitHub Team. On free they exist, they match the right
repos, and `show-rules.sh` lists them; they just don't block
anything. Rulesets on a free org also only apply to **public** repos, so
make the demo repo public.

`ruleset_enforcement` is exposed as a variable if you need to set the
rulesets to `disabled` while iterating. Leave it `active` otherwise,
including on free — it's accurate about intent, and the rulesets begin
enforcing the moment the org is upgraded.

See [`../docs/plan-requirements.md`](../docs/plan-requirements.md) for
the full matrix, including which ruleset rules are Enterprise-only and
what to use instead.

## Prerequisites

Apply `../00-setup` (creates the repo) and `../01-teams-and-permissions`
(creates the team this module grants bypass to) first. The bypass team is
resolved by **slug** via a `github_team` data source in `data.tf`, so a
team that doesn't exist yet fails at plan time with `Not Found` rather
than producing a ruleset whose bypass list points at nothing.

## Running the live demo

```bash
export TF_VAR_github_organization="my-org"
export TF_VAR_bypass_team_slug="security"
export DEMO_REPO="my-org/payments-service"

terraform init && terraform apply

../scripts/show-rules.sh "$DEMO_REPO"   # tier = standard, baseline only
```

Then, in the GitHub UI:

1. **Open a pull request** — `README.md` → pencil → add a line → *Commit
   changes…* → **Create a new branch and start a pull request**. One
   approval required.
2. **Set `tier` to `regulated`** — repo **Settings → Custom properties**.
   You're changing the repository, not the pull request.

```bash
../scripts/show-rules.sh "$DEMO_REPO"   # more rules
```

Reload the pull request. Two approvals, a code owner, three checks, signed
commits, linear history — on a PR nobody pushed to, with no `terraform
apply` in between. A one-line property change onboarded it, and the ruleset
responsible has never heard of this repo by name.

See [`../scripts/README.md`](../scripts) for the terminal-only version, and
`../notebooks/` for the same sequence in Google Colab.

## Notes

- `baseline_protection` and `regulated_repo_protection` are **additive**:
  GitHub merges every ruleset that matches a ref, taking the most
  restrictive value per rule. You are not choosing between them per repo.
- `owning_team` is editable by repo actors on purpose; `tier` is not
  (`org_actors` only). Letting teams self-report *ownership* is fine.
  Letting them self-report their own *compliance scope* defeats the point
  of having one. See `../docs/operational-realities.md`.
