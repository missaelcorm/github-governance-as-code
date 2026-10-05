terraform {
  required_version = ">= 1.7.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

# Auth is intentionally NOT hardcoded here. The provider reads credentials
# from the environment:
#   - PAT:        GITHUB_TOKEN
#   - GitHub App: GITHUB_APP_ID + GITHUB_APP_INSTALLATION_ID + GITHUB_APP_PEM_FILE
#
# This module needs more token scope than the others, because it creates a
# repository and writes files into it:
#   - `repo`     — create the repository, commit files
#   - `workflow` — ONLY needed to commit .github/workflows/ci.yml. Without
#                  it the API rejects that one file with a 403 and nothing
#                  else; set seed_ci_workflow = false to skip it.
#   - `delete_repo` — only if you intend to `terraform destroy` later.
provider "github" {
  owner = var.github_organization
}
