# What you need to run this: GitHub plan requirements

The short version: **you can deploy every module in this repo on a free
GitHub organization.** You do not need GitHub Team, and you do not need
GitHub Enterprise Cloud.

What *does* change with your plan is how much of it actually takes
effect. Two things in particular:

1. On a free org, rulesets only apply to **public** repositories. So the
   demo repos need to be public if you want to see anything get blocked.
2. On a free org, **organization-level rulesets can be created but are
   not enforced.** You need GitHub Team for that. Everything else about
   the module-03 pattern — the custom-property schema, the org rulesets,
   the property-based targeting conditions — applies cleanly and is
   visible in the UI and API.

The rest of this page is the detail behind those two sentences.

## Compatibility matrix

Legend: ✅ works · ⚠️ works with a caveat · ❌ not available

| Capability | Free | Team | Enterprise Cloud | Used by |
|---|:--:|:--:|:--:|---|
| Create a repository, commit files to it | ✅ | ✅ | ✅ | `00` |
| Teams, team membership, team repo access | ✅ | ✅ | ✅ | `01` |
| **Custom repository roles** | ❌ | ❌ | ✅ | — (see below) |
| Repository rulesets, **public** repos | ✅ | ✅ | ✅ | `02` |
| Repository rulesets, **private** repos | ❌ | ✅ | ✅ | `02` |
| Organization custom properties (schema + values) | ✅ | ✅ | ✅ | `03` |
| Organization rulesets — *create and target* | ✅ | ✅ | ✅ | `03` |
| Organization rulesets — **enforced** | ❌ | ✅ | ✅ | `03` |
| Ruleset rule: require PR + approvals | ✅ | ✅ | ✅ | `02`, `03` |
| Ruleset rule: require status checks | ✅ | ✅ | ✅ | `02`, `03` |
| Ruleset rule: require signed commits | ✅ | ✅ | ✅ | `02`, `03` |
| Ruleset rule: require linear history | ✅ | ✅ | ✅ | `02`, `03` |
| Ruleset rule: block deletion / force-push | ✅ | ✅ | ✅ | `02`, `03` |
| Ruleset rule: require code owner review | ⚠️ | ✅ | ✅ | `02`, `03` |
| **Ruleset rule: restrict commit metadata** | ❌ | ❌ | ✅ | — (see below) |
| **Ruleset rule: restrict branch names** | ❌ | ❌ | ✅ | — (see below) |
| Ruleset `enforcement = "evaluate"` (dry run) | ❌ | ❌ | ✅ | — |
| Bypass actors on rulesets | ✅ | ✅ | ✅ | `02`, `03` |

The ✅ rows for free were confirmed by actually applying this repo
against a free organization — creating the custom-property schema and
creating org rulesets both work. The one thing that did *not* work was
enforcement of those org rulesets.

⚠️ **Code owner review on free**: `CODEOWNERS` itself works on public
repos on any plan, so `require_code_owner_review = true` is accepted.
Just remember it only means something if the repo actually has a
`CODEOWNERS` file.

## The three Enterprise-only things, and what to do instead

### 1. Custom repository roles

Defining your own repository role (a named permission set somewhere
between `write` and `admin`) is GitHub Enterprise Cloud only. This repo
doesn't use them — module `01` grants the five built-in repository
permissions (`pull`, `triage`, `push`, `maintain`, `admin`) via
`github_team_repository`, which works on every plan.

If you're on Enterprise and want custom roles, that's
`github_organization_custom_role`. Adding it would make module `01`
un-appliable for everyone else, so it's deliberately not here.

### 2. Restrict commit metadata

The rule family that pattern-matches commit messages, author emails and
committer emails (`commit_message_pattern`,
`commit_author_email_pattern`, `committer_email_pattern` in the
provider) is Enterprise Cloud only.

Not having it mostly costs you conventional-commit enforcement and
"commits must come from a corporate email domain." Both are reasonable
to move into CI as a required status check instead, which is a plan-free
mechanism that works everywhere — and which the rulesets in this repo
already require.

### 3. Restrict branch names

`branch_name_pattern` (and its tag equivalent, `tag_name_pattern`) is
also Enterprise Cloud only. The common use is forcing `feature/*`,
`hotfix/*` style prefixes.

The nearest plan-free substitute is scoping the ruleset itself: a
ruleset whose `conditions.ref_name.include` is `["refs/heads/release/*"]`
won't *stop* someone creating a differently-named branch, but it does
let you attach different protections to different branch namespaces,
which is usually the actual goal.

## Running the module-03 demo on a free org

The pattern in module `03` is the point of the talk, and on a free org
you can build and show all of it — the classification schema, the
rulesets, the property-based targeting, and the fact that tagging a repo
changes which rulesets match it. `scripts/show-rules.sh` will show
the org ruleset listed against the repo once the property value lands.

What you won't get on free is the final beat: a push actually being
rejected by the org ruleset. Three ways to handle that:

- **Upgrade the demo org to Team.** It's the cheapest per-seat paid tier
  and it's what the pattern is designed for. If you're going to demo
  enforcement live, do this.
- **Demo enforcement at the repo level instead.** Repository rulesets
  *are* enforced on free for public repos, so module `02` gives you a
  real "your push was rejected" moment. Then use module `03` to show
  what it looks like when you stop hand-writing that per repo. This is a
  perfectly honest version of the talk — module `02` is the thing you're
  arguing against, so showing it working and still calling it a dead end
  lands fine.
- **Show matching, not blocking.** Run `show-rules.sh` before and after
  changing the property, and let the change in which rulesets apply be the
  payoff. It's a smaller moment but it's the one that's actually about
  classification.

## Repository visibility

On a free organization, rulesets — repository *and* organization level —
only apply to public repositories. Private repos on a free org simply
aren't in scope for rulesets.

Practically this means: **make the demo repos public.** If
`payments-service` is private in a free org, every module in this repo
will still apply successfully, `terraform plan` will be clean, the
ruleset will exist, and absolutely nothing will be protected. That
failure is silent, which makes it worth checking deliberately rather
than assuming.

`00-setup` defaults `repository_visibility` to `public` for exactly this
reason, and its `rulesets_will_be_enforced` output restates it — though
that output can only see the repo's visibility, not your org's plan.

A quick way to confirm what's actually in effect for a repo, whatever
your plan:

```bash
./scripts/show-rules.sh my-org/payments-service
```

If a ruleset you expect is missing from that output, check visibility
and plan before you go debugging the Terraform. The Colab notebook in
`notebooks/` reads your org's plan in its preflight cell and tells you
what to expect before it creates anything.
