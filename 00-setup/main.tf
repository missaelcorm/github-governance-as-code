# The repository everything else governs. Not part of the talk — it exists so
# the demo has a target, and so you can reset with `destroy` + `apply`.

resource "github_repository" "demo" {
  name        = var.repository_name
  description = "Demo repository for the \"Protect your GitHub Repositories at scale with Terraform\" talk. Safe to delete."
  visibility  = var.repository_visibility

  # Also gives the repo a default branch, which `~DEFAULT_BRANCH` in every
  # downstream ruleset condition needs in order to resolve.
  auto_init = true

  # Module 03's regulated tier requires linear history, which blocks merge
  # commits. A repo allowing only merge commits could then never merge.
  allow_merge_commit = false
  allow_squash_merge = true
  allow_rebase_merge = true

  delete_branch_on_merge = true

  has_issues   = false
  has_projects = false
  has_wiki     = false
}

# `rename` handles the case where the org's default branch setting isn't
# `main`; it's a no-op when the names already agree.
resource "github_branch_default" "demo" {
  repository = github_repository.demo.name
  branch     = var.default_branch
  rename     = true
}

# A job's `name:` is what GitHub reports as the check-run name, and that name
# is what a ruleset's required_status_checks matches on — hence the slashes.
# They aren't paths; they just have to agree with modules 02 and 03.
resource "github_repository_file" "ci_workflow" {
  count = var.seed_ci_workflow ? 1 : 0

  repository          = github_repository.demo.name
  branch              = github_branch_default.demo.branch
  file                = ".github/workflows/ci.yml"
  overwrite_on_create = true
  commit_message      = "Add CI workflow reporting the governance-required checks"

  content = <<-YAML
    # Stand-in CI: no real work, just so the required checks report.
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

# Written only when var.codeowners is set.
resource "github_repository_file" "codeowners" {
  count = length(var.codeowners) > 0 ? 1 : 0

  repository          = github_repository.demo.name
  branch              = github_branch_default.demo.branch
  file                = "CODEOWNERS"
  overwrite_on_create = true
  commit_message      = "Add CODEOWNERS"

  content = "* ${join(" ", var.codeowners)}\n"
}
