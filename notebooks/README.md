# Interactive demo (Google Colab)

[`github-governance-demo.ipynb`](./github-governance-demo.ipynb) runs the
talk demo in a browser: installs Terraform and `gh`, applies all four
modules against your organization, then has you open a pull request and
change a property in the GitHub UI to watch the rules change.

## Opening it

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/missaelcorm/protect-github-repos-at-scale/blob/main/notebooks/github-governance-demo.ipynb)

That loads the notebook straight from `main`. Your edits aren't saved back to
the repo — use **File → Save a copy in Drive** to keep them.

Then set `GITHUB_ORG` in the **Configuration** cell (step 2), and `REPO_URL`
if you're running a fork. That's the only edit needed.

## The token goes in Colab Secrets

🔑 in the left sidebar → add a secret named `GITHUB_TOKEN` → **Notebook
access** on. A value pasted into a cell gets saved into the `.ipynb` and
travels with the file when you share it.

A classic PAT with `repo`, `admin:org`, `workflow` and `delete_repo` covers
every cell. Step 3 tells you which you're missing before anything is created.

## It's bash, not Python

Every cell is the same command you'd run in a terminal, bar one Python cell
for reading the Colab secret. Each `%%bash` cell is its own shell, so step 2
writes `/content/env.sh` and later cells source it.

## What it creates in your org

A repository, two teams, three org-level custom properties, and two
organization rulesets. **Point it at a throwaway org.**

Step 8 destroys all of it, and won't run until you set `CONFIRM_ORG` to your org
name. Note the custom-property *schema* is org-wide: destroying module `03`
removes `tier`, `compliance_framework` and `owning_team` for every repo in
the org.

## On a free org

**The notebook needs GitHub Team to get past step 5.** Organization rulesets
can't be created on a free plan — module `03` fails with `403 Upgrade to
GitHub Team to enable this feature`. Step 3 warns you before anything is
created.

Modules `00`, `01` and `02` still work on free, and so does the
custom-property schema. Detail in
[`../docs/plan-requirements.md`](../docs/plan-requirements.md).
