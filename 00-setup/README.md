# 00 — Setup: the repository everything else governs

Not part of the talk. It creates one disposable demo repository with a CI
workflow that reports the checks the rulesets require, so modules `02` and
`03` have something to act on.

Run it first. It's also how you reset between demos: `terraform destroy`,
then apply again.

## Usage

```bash
export TF_VAR_github_organization="my-org"

terraform init
terraform apply
```

## Four things that will bite you

**Visibility.** Defaults to `public` and must stay that way on a free org —
rulesets don't apply to private repos there. Module `02` will apply
cleanly, plan clean, create the ruleset, and protect nothing. Nothing
errors. (Module `03` needs GitHub Team regardless of visibility.) See
[`../docs/plan-requirements.md`](../docs/plan-requirements.md).

**Token scope for the workflow file.** GitHub requires `workflow` for
anything under `.github/workflows/`. Without it that one file 403s while
everything else succeeds. `seed_ci_workflow = false` skips it — but then add
the checks some other way, because a required check that never reports
blocks a PR on "Expected" forever rather than failing it.

**Merge strategies vs. linear history.** Modules `02` and `03` require
linear history, which blocks merge commits. This module turns merge commits
off and leaves squash and rebase on, because a repo allowing *only* merge
commits plus that rule can never merge anything.

**CODEOWNERS is just a file.** You can set `codeowners` on the first apply,
before the team exists — the commit succeeds either way. GitHub reports the
entry as invalid until the named team exists *and* has write access to the
repo, and it starts working by itself once `01-teams-and-permissions` has
run. No second apply here. To see what GitHub thinks of it:

```bash
gh api repos/<org>/<repo>/codeowners/errors
```

The write-access half is the part that catches people: a code-owner entry
for a team that can't write to the repo is never satisfiable, so grant the
team access in `01`.

## Cleaning up

```bash
terraform destroy
```

Needs `delete_repo` on your token, which `repo` doesn't include. If you'd
rather not grant that, delete the repo in the UI and
`terraform state rm github_repository.demo`.
