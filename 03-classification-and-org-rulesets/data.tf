# Resolve the bypass team by slug instead of taking a numeric ID as input.
#
# bypass_actors.actor_id wants a team's numeric ID, which is not something
# anyone knows by heart or wants to copy between modules by hand. Looking
# it up by slug means terraform.tfvars holds "security", not 123456, and a
# team that was deleted and recreated (new ID, same slug) doesn't quietly
# turn the bypass list into a dangling reference.
#
# This does make the module depend on the team already existing — apply
# 01-teams-and-permissions first. If the slug is wrong you get a clean
# "Not Found" at plan time, which is the right failure: better than
# applying a ruleset whose bypass list points at nothing.
data "github_team" "bypass" {
  slug = var.bypass_team_slug

  # Without this the data source also pulls every member and every
  # repository of the team, which is a pile of API calls on every plan
  # just to read one ID. See docs/operational-realities.md §4.
  summary_only = true
}
