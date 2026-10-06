variable "github_organization" {
  description = "GitHub organization to create the demo repository in."
  type        = string
}

variable "repository_name" {
  description = "Name of the demo repository the other modules target."
  type        = string
  default     = "payments-service"
}

variable "default_branch" {
  description = "Default branch. Every ruleset downstream targets ~DEFAULT_BRANCH, which resolves to this."
  type        = string
  default     = "main"
}

variable "repository_visibility" {
  description = <<-DESC
    Keep this "public" unless your org is on GitHub Team or Enterprise.
    On a free org, rulesets only apply to public repos — a private repo
    here means module 02 applies cleanly and protects nothing, with no
    error anywhere. See ../docs/plan-requirements.md.
  DESC
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "private", "internal"], var.repository_visibility)
    error_message = "Must be public, private, or internal (internal requires Enterprise Cloud)."
  }
}

variable "seed_ci_workflow" {
  description = <<-DESC
    Commit a workflow whose job names match the status checks the rulesets
    require. Leave it true: a required check that never reports blocks a PR
    on "Expected" forever instead of failing it, which looks like a broken
    demo rather than a working rule.

    Set it false if your token lacks the `workflow` scope, which GitHub
    requires for any file under .github/workflows/.
  DESC
  type        = bool
  default     = true
}

variable "codeowners" {
  description = <<-DESC
    Owners for CODEOWNERS, e.g. ["@my-org/platform-engineering"]. Empty
    writes no file.

    Safe to set on the first apply, before the team exists: CODEOWNERS is
    just a file, the commit succeeds, and GitHub flags the entry as invalid
    until the named team exists AND has write access to the repo. It starts
    working on its own once 01-teams-and-permissions has run — the file
    doesn't need rewriting, so no second apply here.

    Check what GitHub makes of it:
      gh api repos/<org>/<repo>/codeowners/errors

    Note a code owner can't approve their own pull request, so don't list
    only yourself or the demo PR becomes unmergeable.
  DESC
  type        = list(string)
  default     = []
}
