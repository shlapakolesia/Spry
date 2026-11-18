# Spry

## Infrastructure

The authentication, weekly reports, and agenda parser resources are managed with Terraform in `infra/`. State and remote runs live in the HCP Terraform `spry-dev` workspace, connected to `shlapakolesia/Spry` on `main` with working directory `infra`.

Install Terraform 1.10 or newer and run `terraform login` once. HCP Terraform runs use Remote execution and AWS OIDC dynamic credentials. Keep `database_url`, `google_client_secret`, and `report_email` as sensitive HCP workspace variables; do not put secret values in the repository.

Use `make infra-plan` to review an infrastructure plan. Apply changes through the HCP Terraform run. There is no local Terraform apply target. `make report-now WEEK=2026-W39` reads the report queue URL from Terraform output.

## Google Cloud migration lab

The GCP lab serves the Spry meeting list from Firebase Hosting, with Cloud Run reading synthetic meeting records from Firestore. This keeps the public demo within the recurring free allowances at student traffic, subject to billing-account usage and public traffic.

- [Deployment, authentication, Terraform, verification and cleanup](gcp/README.md)
- [AWS-to-GCP architecture decision](docs/adr/aws-to-gcp-migration.md)
- [Four-scenario pricing comparison](docs/gcp-cost-comparison.md)
- [Data and AI demonstrations](gcp/demos/README.md)
- [Certifications and submission checklist](docs/gcp-submission.md)
- [Observed verification results and evidence](docs/gcp-verification.md)
