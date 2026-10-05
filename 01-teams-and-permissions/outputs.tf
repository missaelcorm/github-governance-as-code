output "team_ids" {
  description = <<-DESC
    Team slug -> numeric team ID.

    Modules 02 and 03 no longer consume this: they resolve their bypass
    team themselves with a `github_team` data source keyed by slug, so
    nobody has to copy an ID between states. It stays exported because
    team IDs are otherwise genuinely hard to find, and anything outside
    Terraform that needs one (an API call, a script, a different tool)
    has to get it from somewhere.
  DESC
  value       = { for k, t in github_team.this : k => t.id }
}

output "team_slugs" {
  description = "The slugs to hand to modules 02 and 03 as bypass_team_slug."
  value       = { for k, t in github_team.this : k => t.slug }
}
