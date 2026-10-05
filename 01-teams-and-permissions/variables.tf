variable "github_organization" {
  description = "GitHub organization this module manages."
  type        = string
}

variable "teams" {
  description = <<-DESC
    Teams to create, keyed by team slug. Each team owns a set of members
    (with an org-team role) — repository access is granted separately via
    var.team_repository_access, so a team's existence and its access to a
    given repo can be reviewed and changed independently.
  DESC
  type = map(object({
    description = string
    privacy     = optional(string, "closed") # "secret" or "closed"
    members = optional(map(object({
      role = optional(string, "member") # "member" or "maintainer"
    })), {})
  }))
}

variable "team_repository_access" {
  description = "Repository permissions granted to teams. Map keys are free-form identifiers, not read by GitHub."
  type = map(object({
    team_slug  = string
    repository = string
    permission = string # pull | triage | push | maintain | admin
  }))
  default = {}
}
