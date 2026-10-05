output "repository_full_name" {
  description = "<org>/<repo> — what scripts/show-rules.sh takes."
  value       = github_repository.demo.full_name
}

output "repository_url" {
  value = github_repository.demo.html_url
}

output "rulesets_will_apply" {
  description = "Reminder, not a real check: it can see the repo's visibility but not your org's plan."
  value = (github_repository.demo.visibility == "public"
    ? "yes — public repo, applies on every plan"
  : "only on GitHub Team or Enterprise Cloud — rulesets skip non-public repos on free")
}
