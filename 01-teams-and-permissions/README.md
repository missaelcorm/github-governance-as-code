# 01 — Teams and permissions

Maps to **talk section 3**. This is the "base blocks" snippet shown on
screen — teams, memberships and repo access, all declarative. It's simple
enough that we move past it quickly in the talk; this module is where the
full version lives.

## Resources used

- `github_team` — create/manage teams
- `github_team_membership` — who's on each team, and at what role
- `github_team_repository` — which teams can access which repos, and at
  what permission level

## Usage

This is the one module that wants a `terraform.tfvars`: `teams` is a map of
objects, which is awkward to express as a `TF_VAR_*` environment variable.
It's the better home for this input anyway — team membership is exactly the
kind of change that should show up as a reviewable diff.

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars for your org

terraform init
terraform plan
terraform apply
```

Members must already be members of the organization — `github_team_membership`
on a non-member fails rather than sending an invitation. Leave `members`
empty if you just need the teams to exist, which is all modules `02` and
`03` require of this one.

## Plan requirements

Everything in this module works on **every GitHub plan, including
free**: teams, team membership and team repository access are all
free-plan features.

Repository access here uses GitHub's five built-in permission levels
(`pull`, `triage`, `push`, `maintain`, `admin`). **Custom repository
roles** — defining your own named permission set — are GitHub Enterprise
Cloud only, which is why they're not used here. See
[`../docs/plan-requirements.md`](../docs/plan-requirements.md).

## Notes

- Team **membership** and repo **access** are modeled as two separate
  resources/variables on purpose: adding someone to a team is a people
  decision, granting a team access to a repo is an architecture decision.
  Keeping them apart makes diffs in PRs easier to reason about.
- **Apply this before modules `02` and `03`.** Both resolve their bypass
  team by slug with a `github_team` data source, so the team has to exist
  first or they fail at plan time with `Not Found`.
- `team_ids` and `team_slugs` are both exported. The modules here use
  slugs; `team_ids` is there for anything outside Terraform that needs a
  numeric ID.
