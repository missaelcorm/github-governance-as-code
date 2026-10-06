# What you need to run this: GitHub plan requirements

The short version:

- Modules **`00`, `01` and `02`** run on a **free** organization.
- Module **`03`** — the core pattern, and the point of the talk — needs
  **GitHub Team** or Enterprise Cloud. Organization rulesets cannot be
  created on a free plan at all.

Worth knowing where the line falls: **organization custom properties work
on a free org.** You can define a classification schema, tag every repo,
and read the values back. What you can't do on free is create the
organization rulesets that *act* on those values. Free gets you
classification without enforcement.

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

### Verified on a free org

Applying this repo against a real free organization: the custom properties
in `properties.tf` applied fine, and both org rulesets failed with

```
Error: POST https://api.github.com/orgs/<org>/rulesets:
403 Upgrade to GitHub Team to enable this feature.
```

The UI is more permissive here than the API, so trust `terraform apply`
over a settings page when working out what your plan allows.

The rest of the table is from GitHub's published plan tiers, not our own
testing — worth verifying the rows you depend on before you rely on them.

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

**On a free org**, module `03` fails with the 403 above. Two options:

- **Upgrade the demo org to Team.** The cheapest paid tier, and what the
  pattern needs. There's no workaround that preserves the point.
- **Show the classification half only.** `properties.tf` works on free, so
  you can tag repos and show the classification layer, with module `02`'s
  repo-level ruleset as what you're replacing. You can describe the join
  between them, not show it.

## Repository visibility

On a free organization, rulesets only apply to public repositories.
Private repos on a free org aren't in scope for rulesets at all.

So on free: **make the demo repos public.** If `payments-service` is
private, module `02` applies successfully, `terraform plan` stays clean,
the ruleset exists in the API, and nothing is protected — with no error
anywhere. `00-setup` defaults `repository_visibility` to `public` for this
reason.

A quick way to confirm what's actually in effect for a repo, whatever your
plan:

```bash
./scripts/show-rules.sh my-org/payments-service
```

An empty rule list means nothing applies. Check plan and visibility before
debugging the Terraform. The Colab notebook in `notebooks/` reads your
org's plan in its preflight cell and warns you before it creates anything.
