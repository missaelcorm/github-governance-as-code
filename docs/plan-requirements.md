# What you need to run this: GitHub plan requirements

The short version:

- Modules **`00`, `01` and `02`** run on a **free** organization.
- Module **`03`** — the core pattern, and the point of the talk — needs
  **GitHub Team** or Enterprise Cloud. Organization rulesets cannot be
  created on a free plan at all.

There's a wrinkle worth knowing, because it's genuinely useful and it's
the thing that misled us: **organization custom properties work on a free
org.** You can define a classification schema, tag every repo in the org,
and read the values back. What you can't do on free is create the
organization rulesets that *act* on those values. So free gets you
classification without enforcement — half the pattern, and the half that
produces no security benefit on its own.

## Compatibility matrix

Legend: ✅ works · ⚠️ works with a caveat · ❌ not available

| Capability | Free | Team | Enterprise Cloud | Used by |
|---|:--:|:--:|:--:|---|
| Create a repository, commit files to it | ✅ | ✅ | ✅ | `00` |
| Teams, team membership, team repo access | ✅ | ✅ | ✅ | `01` |
| **Custom repository roles** | ❌ | ❌ | ✅ | — |
| Repository rulesets, **public** repos | ✅ | ✅ | ✅ | `02` |
| Repository rulesets, **private** repos | ❌ | ✅ | ✅ | `02` |
| Organization custom properties (schema + values) | ✅ | ✅ | ✅ | `03` |
| **Organization rulesets** | ❌ | ✅ | ✅ | `03` |
| Ruleset rule: require PR + approvals | ✅ | ✅ | ✅ | `02`, `03` |
| Ruleset rule: require status checks | ✅ | ✅ | ✅ | `02`, `03` |
| Ruleset rule: require signed commits | ✅ | ✅ | ✅ | `02`, `03` |
| Ruleset rule: require linear history | ✅ | ✅ | ✅ | `02`, `03` |
| Ruleset rule: block deletion / force-push | ✅ | ✅ | ✅ | `02`, `03` |
| Ruleset rule: require code owner review | ⚠️ | ✅ | ✅ | `02`, `03` |
| **Ruleset rule: restrict commit metadata** | ❌ | ❌ | ✅ | — |
| **Ruleset rule: restrict branch names** | ❌ | ❌ | ✅ | — |
| Ruleset `enforcement = "evaluate"` (dry run) | ❌ | ❌ | ✅ | — |
| Bypass actors on rulesets | ✅ | ✅ | ✅ | `02`, `03` |

⚠️ **Code owner review on free**: `CODEOWNERS` works on public repos on
any plan, so `require_code_owner_review = true` is accepted. It only means
something if the repo actually has a `CODEOWNERS` file naming a team that
exists.

### How we know

Two rows were established by applying this repo against a real free
organization:

- **Organization custom properties: yes.** The three
  `github_organization_custom_properties` resources in `properties.tf`
  applied without complaint.
- **Organization rulesets: no.** Both org rulesets failed, and the error
  is unambiguous:

  ```
  Error: POST https://api.github.com/orgs/<org>/rulesets:
  403 Upgrade to GitHub Team to enable this feature.
  ```

  It's a hard 403 at creation. An earlier version of this document claimed
  org rulesets could be created on free and merely weren't enforced —
  that was wrong, and if you read it, this is the correction. The GitHub
  UI appears more permissive here than the API is, which is a good reason
  to trust `terraform apply` over a settings page when working out what
  your plan allows.

Everything else in the table is from GitHub's published plan tiers rather
than from our own testing. Given that one inherited claim already turned
out to be wrong, treat the ❌ rows you depend on as worth five minutes of
verification against your own org before you rely on them on stage.

## The three Enterprise-only things, and what to do instead

### 1. Custom repository roles

Defining your own repository role — a named permission set between
`write` and `admin` — is Enterprise Cloud only. This repo doesn't use
them: module `01` grants the five built-in repository permissions
(`pull`, `triage`, `push`, `maintain`, `admin`) via
`github_team_repository`, which works everywhere.

On Enterprise that's `github_organization_custom_role`. Adding it would
make module `01` un-appliable for everyone else, so it's deliberately
absent.

### 2. Restrict commit metadata

The rules that pattern-match commit messages, author emails and committer
emails (`commit_message_pattern`, `commit_author_email_pattern`,
`committer_email_pattern`) are Enterprise Cloud only.

Not having them mostly costs you conventional-commit enforcement and
"commits must come from a corporate email domain." Both are reasonable to
move into CI as a required status check, which works on every plan — and
which the rulesets here already require.

### 3. Restrict branch names

`branch_name_pattern` (and `tag_name_pattern` for the tag target) is also
Enterprise Cloud only. The common use is forcing `feature/*` or
`hotfix/*` prefixes.

The nearest plan-free substitute is scoping the ruleset itself: a ruleset
whose `conditions.ref_name.include` is `["refs/heads/release/*"]` won't
*stop* someone creating a differently-named branch, but it does let you
attach different protections to different branch namespaces, which is
usually the actual goal.

## Running the demo

**On Team or Enterprise Cloud**, everything works as documented. This is
what the talk assumes.

**On a free org**, module `03` will fail with the 403 above. You have two
honest options:

- **Upgrade the demo org to Team.** It's the cheapest paid tier and it's
  what the pattern is designed for. If you're demoing the pattern, do
  this — there is no workaround that preserves the point.
- **Demo the classification half only, and say so.** Apply
  `properties.tf` (which works on free), tag repos, and show that the
  classification layer is free and easy. Then show module `02`'s
  repository-level ruleset — enforced on free public repos — as what
  you're replacing. You can describe the join between them, but you can't
  show it.

What you can't do is show the payoff on a free org. The whole pattern is
classification *driving* enforcement, and the mechanism that connects
them is the one thing free doesn't have.

## Repository visibility

On a free organization, rulesets only apply to public repositories.
Private repos on a free org aren't in scope for rulesets at all.

So on free: **make the demo repos public.** If `payments-service` is
private, module `02` applies successfully, `terraform plan` stays clean,
the ruleset exists in the API, and nothing is protected. That failure is
silent, which makes it worth checking deliberately.

`00-setup` defaults `repository_visibility` to `public` for this reason,
and its `rulesets_will_apply` output restates it — though that output can
only see the repo's visibility, not your org's plan.

A quick way to confirm what's actually in effect for a repo, whatever your
plan:

```bash
./scripts/show-rules.sh my-org/payments-service
```

An empty rule list means nothing applies. Check plan and visibility before
debugging the Terraform. The Colab notebook in `notebooks/` reads your
org's plan in its preflight cell and warns you before it creates anything.
