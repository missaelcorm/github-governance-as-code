resource "github_team" "this" {
  for_each    = var.teams
  name        = each.key
  description = each.value.description
  privacy     = each.value.privacy
}

locals {
  # Flatten team -> members map into a single map Terraform can for_each
  # over: "team-slug/username" => { team_key, username, role }.
  team_memberships = merge([
    for team_key, team in var.teams : {
      for username, member in team.members :
      "${team_key}/${username}" => {
        team_key = team_key
        username = username
        role     = member.role
      }
    }
  ]...)
}

resource "github_team_membership" "this" {
  for_each = local.team_memberships

  team_id  = github_team.this[each.value.team_key].id
  username = each.value.username
  role     = each.value.role
}

resource "github_team_repository" "this" {
  for_each = var.team_repository_access

  team_id    = github_team.this[each.value.team_slug].id
  repository = each.value.repository
  permission = each.value.permission
}
