# 02 — Repository-level ruleset

Maps to **talk section 4**. One `github_repository_ruleset`, scoped to a
single repo: required reviews, required status checks, bypass actors,
linear history — the direct Terraform replacement for classic branch
protection.

## Why this doesn't scale

This module has exactly one dial: `repository_name`. Protecting the next
repo means another `module` block (or another apply of this one with
different vars) — and another, and another. Two hundred repos means two
hundred near-identical blocks quietly drifting apart as people copy-paste
and forget to update one of them.

That's the problem module `03-classification-and-org-rulesets` solves:
instead of one ruleset per repo, one ruleset targets *every* repo that
carries the right classification.

## Usage

```bash
export TF_VAR_github_organization="my-org"
export TF_VAR_repository_name="payments-service"
export TF_VAR_bypass_team_slug="security"   # omit for no bypass at all

terraform init
terraform plan
terraform apply
```

`bypass_team_slug` takes a team name, not a numeric ID — `data.tf`
resolves it. That means `../01-teams-and-permissions` has to be applied
first, unless you leave the variable unset.

## Plan requirements

Repository rulesets work on **every GitHub plan, including free** — with
one condition on free: they only apply to **public** repositories. On a
free org, a ruleset on a private repo applies successfully and protects
nothing.

That makes this module the one place a free org gets genuinely *enforced*
protection, which is worth knowing if you're running the talk's demo on
free: org rulesets (module `03`) can be created there but aren't enforced
until GitHub Team. Awkwardly, that means the module this talk argues
against is the one that visibly blocks a push on free. It's still fine to
show — being enforced was never the problem with it.

Every rule used here works on any plan. See
[`../docs/plan-requirements.md`](../docs/plan-requirements.md) for the
rules that don't (restrict commit metadata, restrict branch names — both
Enterprise Cloud).
