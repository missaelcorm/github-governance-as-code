# Demo helpers

One script. The demo itself happens in the GitHub UI, where the audience
can see it — the script is just the part that's easier to read as text
than as a settings page.

| Script          | Shows                                                      |
|-----------------|------------------------------------------------------------|
| `show-rules.sh` | A repo's custom properties, and the rules they earn it     |

Needs the [GitHub CLI](https://cli.github.com/) authenticated
(`gh auth login`). Reading rules needs repo read access; the demo's
property change needs the org's "custom properties" permission.

## The demo

Run `00-setup`, `01-teams-and-permissions` and
`03-classification-and-org-rulesets` first, then:

```bash
./show-rules.sh my-org/payments-service
```

`tier = standard`, and a short rule list — `baseline-protection` only.

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

More rules now. Reload the pull request from step 1 — same PR, nobody
pushed to it, no `terraform apply` ran — and the merge box asks for two
approvals, a code owner, and three checks.

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
repos. Check visibility before debugging the Terraform.
