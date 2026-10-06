# Demo helpers

One script. The demo itself happens in the GitHub UI, where the audience
can see it — the script is just the part that's easier to read as text
than as a settings page.

| Script          | Shows                                                      |
|-----------------|------------------------------------------------------------|
| `show-rules.sh` | A repo's custom properties, and the rules they earn it     |

Its output has three parts: the properties set on the repo, the rules
**grouped by the ruleset that contributes them**, and the strictest value
in effect for the ones that take parameters.

The grouping matters because the rules API identifies a ruleset by ID and
reports its `ruleset_source` as the org or repo that *owns* it, not the
ruleset's own name — so raw output labels every org-level rule
`Organization ruleset "my-org"` and you can't tell `baseline-protection`
from `regulated-repo-protection`. The script looks the names up. Listing
org rulesets needs `admin:org`; without it you get bare IDs.

Seeing the same rule type under two rulesets is normal, not a bug — that's
aggregation, and the "strictest values" block is that merge resolved.

Needs the [GitHub CLI](https://cli.github.com/) authenticated
(`gh auth login`). Reading rules needs repo read access; the demo's
property change needs the org's "custom properties" permission.

## The demo

Run `00-setup`, `01-teams-and-permissions` and
`03-classification-and-org-rulesets` first, then:

```bash
./show-rules.sh my-org/payments-service
```

`tier = standard`: `baseline-protection` from the org, plus module `02`'s
repo-level ruleset if you applied it. One approval required.

**1. Open a pull request, in the UI.** On the repo, open `README.md` →
pencil icon → add a line → *Commit changes…* → **Create a new branch and
start a pull request**. Four clicks, a real diff, a real PR. Look at the
merge box: one approval required.

**2. Reclassify the repo, in the UI.** Repo **Settings → Custom
properties** → set `tier` to `regulated` → save.

**3. Ask again.**

```bash
./show-rules.sh my-org/payments-service
```

More rules now, and watch for two kinds of change. New rule *types*
(`required_signatures`, `required_linear_history`) and rule types that were
already there but got **stricter** — `pull_request` appears in both runs;
what changed is that it went from one approval to two plus a code owner.
The second kind is easy to miss, which is what the "strictest values" block
is for.

Reload the pull request from step 1 — same PR, nobody pushed to it, no
`terraform apply` ran — and the merge box now asks for two approvals, a
code owner, and three checks.

That's the whole argument. The rules changed because the repo's
classification changed, and the ruleset that did it has never heard of
this repo by name.

## Doing it from a terminal instead

Both UI steps are one command each, if you'd rather not click:

```bash
# Set a property value. The payload goes in on stdin because `-f` can't
# express an array of objects.
gh api --method PATCH "repos/my-org/payments-service/properties/values" \
  --input - <<'JSON'
{ "properties": [ { "property_name": "tier", "value": "regulated" } ] }
JSON

# Open a pull request from a branch you've already pushed
gh pr create --repo my-org/payments-service --fill
```

The UI is usually the better choice on stage: it makes the point that
classification is a thing anyone can set — from a settings page, an
onboarding pipeline, or Terraform — while enforcement stays centralized.

## Two things that look like failures and aren't

**A required check stuck on "Expected".** Nothing ever reported it, so
GitHub waits forever instead of failing. Usually the CI workflow didn't
get committed — see `seed_ci_workflow` in `00-setup`.

**An empty rule list.** On a free org, rulesets only apply to public
repos — check visibility before debugging the Terraform. And if module
`03` never applied because of its `403 Upgrade to GitHub Team`, there are
no org rulesets to find.
