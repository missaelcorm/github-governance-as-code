variable "github_organization" {
  description = "GitHub organization this module manages."
  type        = string
}

variable "bypass_team_slug" {
  description = <<-DESC
    Slug of the team allowed to bypass these org rulesets (e.g. security
    engineering). Resolved to a numeric team ID by the data source in
    data.tf, so you give it a name rather than an ID.

    The team has to exist before this module is applied — apply
    01-teams-and-permissions first, with this slug among its teams.
  DESC
  type        = string
  default     = "security"
}

variable "ruleset_enforcement" {
  description = <<-DESC
    Enforcement mode for the org rulesets in rulesets.tf.

    "active" is what you want in production, and the default.

    "disabled" makes the rulesets exist without applying — useful while
    iterating. "evaluate" (dry run: log what would have been blocked,
    block nothing) is GitHub Enterprise Cloud only and is rejected on
    other plans.

    None of these help on a free org: org rulesets can't be created there
    at any enforcement level.

    See ../docs/plan-requirements.md.
  DESC
  type        = string
  default     = "active"

  validation {
    condition     = contains(["active", "evaluate", "disabled"], var.ruleset_enforcement)
    error_message = "ruleset_enforcement must be one of: active, evaluate, disabled. Note that \"evaluate\" requires GitHub Enterprise Cloud."
  }
}
