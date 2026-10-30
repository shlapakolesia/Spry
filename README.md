# Spry

## Infrastructure

The authentication, weekly reports, and agenda parser resources are managed with Terraform in `infra/`. State and remote runs live in the HCP Terraform `spry-dev` workspace, connected to `shlapakolesia/Spry` on `main` with working directory `infra`.

Install Terraform 1.10 or newer and run `terraform login` once. HCP Terraform runs use Remote execution and AWS OIDC dynamic credentials. Keep `database_url`, `google_client_secret`, and `report_email` as sensitive HCP workspace variables; do not put secret values in the repository.

Use `make infra-plan` to review an infrastructure plan. Apply changes through the HCP Terraform run. There is no local Terraform apply target. `make report-now WEEK=2026-W39` reads the report queue URL from Terraform output.
