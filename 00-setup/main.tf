# The repository everything else governs. Not part of the talk's narrative —
# it exists so the demo has a target, and so you can reset between runs with
# `terraform destroy` + `apply` instead of clicking a repo back together.
#
# It's the only module here that creates a repository, and should stay that
# way: this repo is about managing policy, not about managing every repo in
# an org from Terraform.

resource "github_repository" "demo" {
  name        = var.repository_name
  description = "Demo repository for the GitHub governance-as-code talk. Safe to delete."
  visibility  = var.repository_visibility

  # Creates the first commit and a README for the demo PR to edit. Without
  # it the repo has no default branch, and `~DEFAULT_BRANCH` in every
  # downstream ruleset condition resolves to nothing.
  auto_init = true

  # required_linear_history in modules 02 and 03 blocks merge commits. A repo
  # that allows *only* merge commits plus that rule can never merge anything,
  # and GitHub doesn't explain why. Squash and rebase both stay linear.
  allow_merge_commit = false
  allow_squash_merge = true
  allow_rebase_merge = true

  delete_branch_on_merge = true

  has_issues   = false
  has_projects = false
  has_wiki     = false
}

# auto_init names the first branch after the organization's default branch
# setting, which isn't necessarily `main`. `rename` handles the mismatch
# instead of failing, and is a no-op when the names already agree.
resource "github_branch_default" "demo" {
  repository = github_repository.demo.name
  branch     = var.default_branch
  rename     = true
}

# Status checks named to match what the rulesets require. The job `name:` is
# what GitHub reports as the check-run name, and that name is what a ruleset
# matches on — hence the slashes. They aren't paths; they just have to agree
# with modules 02 and 03.
resource "github_repository_file" "ci_workflow" {
  count = var.seed_ci_workflow ? 1 : 0

  repository          = github_repository.demo.name
  branch              = github_branch_default.demo.branch
  file                = ".github/workflows/ci.yml"
  overwrite_on_create = true
  commit_message      = "Add CI workflow reporting the governance-required checks"

  content = <<-YAML
    # Stand-in CI. These jobs do no real work — they exist so the checks the
    # rulesets require actually report instead of hanging as "Expected".
    name: ci

    on:
      pull_request:
      push:
        branches: [${github_branch_default.demo.branch}]

    permissions:
      contents: read

    jobs:
      build:
        name: ci/build
        runs-on: ubuntu-latest
        steps:
          - run: echo "build ok"

      test:
        name: ci/test
        runs-on: ubuntu-latest
        steps:
          - run: echo "tests ok"

      sast:
        name: security/sast
        runs-on: ubuntu-latest
        steps:
          - run: echo "no findings"
  YAML
}

# Written only when var.codeowners is set. Safe to write before the team it
# names exists — it's a plain file, and GitHub just reports the entry as
# invalid (see /codeowners/errors) until the team is there with write access.
resource "github_repository_file" "codeowners" {
  count = length(var.codeowners) > 0 ? 1 : 0

  repository          = github_repository.demo.name
  branch              = github_branch_default.demo.branch
  file                = "CODEOWNERS"
  overwrite_on_create = true
  commit_message      = "Add CODEOWNERS"

  content = "* ${join(" ", var.codeowners)}\n"
}
