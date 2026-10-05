# Operational realities at scale

Maps to **talk section 6**. The slide only has headlines — this is the
detail behind each one.

> **Plan note.** Everything below applies on any GitHub plan. What
> changes by plan is which governance primitives exist at all — see
> [`plan-requirements.md`](./plan-requirements.md). The short version:
> the whole repo deploys on a free org, but rulesets there only cover
> public repos and org rulesets aren't enforced until GitHub Team.

## 1. Drift detection

Two sources of drift, and they need different answers:

- **Config drift**: someone changes something Terraform manages (a
  ruleset, a team's repo permission) directly in the UI or API. Catch this
  with a scheduled `terraform plan` in CI (nightly is usually enough for
  governance config — it doesn't change as fast as application infra) that
  posts a diff or opens an issue on non-empty plans. Don't auto-apply on
  schedule for this kind of config; a silent, unreviewed apply of security
  policy is its own risk. A dedicated drift tool (e.g. driftctl-style
  scanning, or your Terraform platform's built-in drift detection if
  you're on Terraform Cloud/HCP Terraform) gets you the same signal with
  less custom CI plumbing.
- **Structural drift by design**: `values_editable_by = "org_and_repo_actors"`
  on a custom property (see `owning_team` in module 03) means repo actors
  can change that value *outside Terraform, on purpose*. That's not drift
  to fix — it's a deliberate self-service boundary. Decide per property
  which category it's in, and keep governance-relevant properties
  (`tier`, `compliance_framework`) `org_actors`-only so their drift really
  does mean "something to investigate."

There's a third thing that looks like drift and isn't: on a free org,
org rulesets exist and match repos but don't enforce. `terraform plan`
is clean, the API shows the ruleset, and pushes that should be blocked
go through. That's a plan limit, not drift — check
[`plan-requirements.md`](./plan-requirements.md) before you debug it as
one.

## 2. Terraform state strategy

At one organization with a handful of repos, one state file is fine. At
several organizations and hundreds of repos, state layout becomes a
blast-radius decision:

- Split state by **change frequency and risk**, not just by resource
  type. This repo's three modules aren't an accident: team membership
  changes weekly and is low-risk if wrong; org rulesets change rarely and
  are high-risk if wrong. Different cadence and different risk profile
  argue for different state files, different review requirements, and
  possibly different apply permissions.
- Split state **per GitHub organization** if you manage more than one —
  a bad apply should never be able to touch an org it wasn't scoped to.
- Use remote state with locking (Terraform Cloud/HCP Terraform, or
  S3+DynamoDB / GCS / Azure Storage equivalents) regardless of scale —
  local state for anything touching shared GitHub org settings is asking
  for two people to clobber each other's changes.

## 3. Authentication: GitHub App vs PAT

| | Personal Access Token | GitHub App |
|---|---|---|
| Tied to | An individual human | The app installation |
| Breaks when | That person leaves / rotates their token | Never, as long as the app exists |
| Rate limit | Shared with that user's other API usage | Separate pool, scales with installation |
| Rotation | Manual (or short-lived fine-grained PATs, still manual renewal) | Automatic (installation tokens expire hourly and are reissued) |
| Audit trail | Attributed to the person | Attributed to the app |

For a CI/CD pipeline applying org-wide governance, a GitHub App is close
to strictly better: it survives offboarding, doesn't quietly stop working
because someone's token expired, and gives you a clean audit trail that
says "the governance pipeline did this," not "Alice's PAT did this." PATs
are fine for local `terraform plan` while iterating, and fine at small
scale — just don't build the org's security posture on one person's token
surviving.

## 4. Rate limits

- The GitHub REST API's primary rate limit is a per-hour budget on the
  authenticated identity — small at PAT scale, larger and pooled
  differently for GitHub App installations. Provisioning hundreds of
  repos' worth of rulesets, properties, and team grants in one `apply` can
  burn through that budget, especially on `terraform plan`, which reads
  every managed resource's current state before showing you anything.
- GitHub also enforces **secondary/abuse rate limits** on rapid
  concentrated writes (e.g. creating many resources back-to-back), which
  are separate from the primary limit and easy to trip during a large
  first-time `apply` or a bulk onboarding run.
- Practical mitigations: lower Terraform's `-parallelism` (default 10)
  for GitHub-heavy applies, batch onboarding in waves rather than one
  apply touching everything at once, and prefer the org-level ruleset
  pattern in module 03 specifically because it turns "protect 200 repos"
  into "one ruleset apply, then N cheap property writes" instead of N
  ruleset applies.

## 5. Plan limits are part of your threat model

A governance control that exists but doesn't enforce is worse than no
control, because it reads as covered on a dashboard. Two ways this
happens in practice with GitHub:

- **Free org, org-level ruleset.** Created, targeted, visible, not
  enforced. Needs GitHub Team.
- **Free org, private repo.** Rulesets don't apply to private repos on
  free at all — and the repos you'd most want protected are the ones
  most likely to be private.

Neither shows up as a Terraform error or a non-empty plan, so neither
gets caught by the drift detection in §1. If you're running governance
on a free org, verify enforcement out-of-band: push something that
should be rejected to a throwaway branch and confirm it actually is.
Once per policy change is enough; the point is to not learn it during an
audit.

Full matrix: [`plan-requirements.md`](./plan-requirements.md).
