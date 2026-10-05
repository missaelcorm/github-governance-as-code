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

    "active" is correct on every plan and is what you want in
    production. Note that on a FREE organization, org rulesets are
    created and targeted correctly but are not actually enforced — that
    requires GitHub Team. Setting this to "active" on free is still the
    right thing to do: it's accurate about intent, and the rulesets
    start enforcing the moment the org is upgraded.

    "disabled" is available on any plan if you want the rulesets to
    exist without applying. "evaluate" (dry-run: log what would have
    been blocked, block nothing) is GitHub Enterprise Cloud only and
    will be rejected on other plans.

    See ../docs/plan-requirements.md.
  DESC
  type        = string
  default     = "active"

  validation {
    condition     = contains(["active", "evaluate", "disabled"], var.ruleset_enforcement)
    error_message = "ruleset_enforcement must be one of: active, evaluate, disabled. Note that \"evaluate\" requires GitHub Enterprise Cloud."
  }
}
