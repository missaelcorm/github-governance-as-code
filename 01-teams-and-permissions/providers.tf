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
# See ../docs/operational-realities.md for why a GitHub App is the better
# default once this is running in CI.
provider "github" {
  owner = var.github_organization
}
