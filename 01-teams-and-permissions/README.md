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

This is the one module that really wants a `terraform.tfvars`. The others
take a handful of scalars you can export as `TF_VAR_*` (see the top-level
README); `teams` here is a map of objects, and expressing that through an
environment variable means hand-writing JSON. A file is better anyway for
this particular input — who is on which team is exactly the kind of change
that should show up as a reviewable diff.

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
- **Apply this before modules `02` and `03`.** Both grant ruleset bypass
  rights to a team, and both resolve it with a `github_team` data source
  keyed by slug — so the team has to exist first or they fail at plan
  time with `Not Found`. That's the intended failure: a ruleset whose
  bypass list silently points at nothing is worse than one that won't
  plan.
- `team_ids` and `team_slugs` are both exported. Nothing in this repo
  consumes `team_ids` any more — looking the team up by slug beats
  copying a numeric ID between states, and survives a team being deleted
  and recreated. It's still exported because team IDs are hard to find
  by hand and anything outside Terraform that needs one has to get it
  somewhere.
