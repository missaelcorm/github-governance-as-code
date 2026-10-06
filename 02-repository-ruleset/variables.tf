variable "github_organization" {
  description = "GitHub organization this module manages."
  type        = string
}

variable "repository_name" {
  description = "Repository this ruleset is scoped to. This is a repository-level ruleset — see module 03 for the org-level, scale-friendly version."
  type        = string
}

variable "required_review_count" {
  description = <<-DESC
    Approving reviews required before merge.

    Keep this at 1. Rules aggregate across every ruleset matching a ref and
    the strictest value wins, so a 2 here would mask module 03's regulated
    tier — which also asks for 2 — and reclassifying a repo would appear to
    change nothing.
  DESC
  type        = number
  default     = 1
}

variable "required_status_checks" {
  description = "CI check contexts that must report success before merge."
  type        = list(string)
  default     = ["ci/build", "ci/test"]
}

variable "bypass_team_slug" {
  description = <<-DESC
    Slug of the team allowed to bypass this ruleset (e.g. release
    managers). Resolved to a numeric team ID by data.tf, so this takes a
    name rather than an ID — and the team must already exist.

    Leave null to grant no bypass at all, which also skips the lookup.
  DESC
  type        = string
  default     = null
}
