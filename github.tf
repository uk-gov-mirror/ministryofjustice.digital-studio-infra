provider "github" {
  # token = "..." use GITHUB_TOKEN env var
  organization = "noms-digital-studio"
}

provider "github" {
  alias = "moj"
  # token = "..." use GITHUB_TOKEN env var
  organization = "ministryofjustice"
}
