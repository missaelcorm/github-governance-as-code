# Interactive demo (Google Colab)

[`github-governance-demo.ipynb`](./github-governance-demo.ipynb) runs the
talk demo in a browser: installs Terraform and `gh`, applies all four
modules against your organization, and then has you open a pull request and
change a property in the GitHub UI so you can watch the rules change.

Useful as a fallback when the conference wifi is hostile, and as the thing
to hand someone afterwards who wants to try the pattern without installing
anything.

## Importing it

1. Open [colab.research.google.com](https://colab.research.google.com).
2. **File → Open notebook → GitHub**, paste
   `https://github.com/missaelcorm/github-governance-as-code`, and pick
   `notebooks/github-governance-demo.ipynb`.
3. In the **§2 Configuration** cell, set `GITHUB_ORG`. That's the only edit
   needed — and `REPO_URL` if you're running a fork.

## The token goes in Colab Secrets

🔑 in the left sidebar → add a secret named `GITHUB_TOKEN` → **Notebook
access** on.

This is the one place the notebook deliberately diverges from the top-level
README, which uses `export GITHUB_TOKEN=...`. A shell variable dies with the
shell. A value pasted into a cell gets saved into the `.ipynb`, lives in the
cell output, and travels with the file when you share it — and this token
can administer your organization.

A classic PAT with `repo`, `admin:org`, `workflow` and `delete_repo` covers
every cell. §3 tells you which you're missing before anything is created.

## It's bash, not Python

Every cell is the same command you'd run in a terminal. There's exactly one
Python cell, four lines, because `%%bash` can't reach Colab's secrets API.

Each `%%bash` cell is its own shell, so an `export` in one is gone by the
next. That's why §2 writes `/content/env.sh` and later cells open with
`source /content/env.sh` — the notebook's `.envrc`.

## What it creates in your org

A repository, a team, three org-level custom properties, and two
organization rulesets. **Point it at a throwaway org.**

§9 destroys all of it, and won't run until you set `CONFIRM_ORG` to your org
name. One thing it can't undo cleanly: the custom-property *schema* is
org-wide, so destroying module `03` removes `tier`, `compliance_framework`
and `owning_team` for **every** repo in the org, along with any values set
on them. On a shared org that isn't demo cleanup.

## On a free org

§3 reads your org's plan and says what to expect. On free you'll see the
rules applying to the repo change when its classification changes — which is
the demo — but you won't see an org ruleset block anything, because free orgs
don't enforce them. Run §6 to also deploy the repository-level ruleset, which
*is* enforced on free public repos, if you want something visibly blocked.
Detail in [`../docs/plan-requirements.md`](../docs/plan-requirements.md).
