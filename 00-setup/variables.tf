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
    Keep this "public" on a free org: rulesets only apply to public repos
    there, and a private repo is protected by nothing with no error shown.
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
    require. Without it, those checks never report and pull requests sit on
    "Expected" forever rather than failing.

    Needs the `workflow` token scope, which GitHub requires for any file
    under .github/workflows/.
  DESC
  type        = bool
  default     = true
}

variable "codeowners" {
  description = <<-DESC
    Owners for CODEOWNERS, e.g. ["@my-org/platform-engineering"]. Empty
    writes no file.

    The named team needs write access to the repo to count as an owner.
    Check with: gh api repos/<org>/<repo>/codeowners/errors

    A code owner can't approve their own pull request.
  DESC
  type        = list(string)
  default     = []
}
