# bypass_actors.actor_id wants a numeric team ID. Looking it up by slug keeps
# IDs out of terraform.tfvars and survives a team being deleted and recreated.
#
# Requires the team to exist — apply 01-teams-and-permissions first, or this
# fails at plan time with "Not Found".
data "github_team" "bypass" {
  slug = var.bypass_team_slug

  # Without this the lookup also pulls every member and repository of the
  # team, on every plan, to read one ID.
  summary_only = true
}
