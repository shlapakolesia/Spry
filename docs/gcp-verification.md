# Spry verification record

Runs on 18 and 19 November 2026 on branch `lab-gcp`.

| Check | Observed result |
|---|---|
| GCP application project | `spry-ucu-lab-2026-a83f`, linked to the verified, unupgraded Google Cloud Free Trial |
| Terraform format and validate | Both Google roots passed, using Google provider 7.46.2. AWS state was untouched. |
| HCP Terraform | Created two private GCP workspaces with Local execution under the free plan. The Firestore bootstrap state was migrated and verified. AWS remains in `spry-dev`. |
| Terraform plan | Reviewed plans proposed eight bootstrap creates and one Cloud Run create with the published image digest. Both applied successfully with zero changes or deletions. |
| Terraform apply | A reviewed two-resource bootstrap plan enabled Firestore and created the default database. The original ADC identity lacked Service Usage access. The apply succeeded with a short-lived token from the authenticated gcloud CLI session. A separate screened IAM-only plan then added 12 resources to the still-unbilled project. |
| GCP IAM and WIF | Separate runtime, deployer and publisher accounts. The live GitHub provider restricts authorization to the numeric repository and owner IDs and branch. All three accounts had zero user-managed keys. The deployment image was pushed manually to the regional registry. GitHub image publishing remains gated. |
| Firestore | Native, Standard, `us-central1`, PITR disabled. Seeded `lab_meetings/1`. Local FastAPI test client with an operator token returned HTTP 200 and the actual cloud record. See [response evidence](evidence/firestore-api.json). The deployed Cloud Run runtime then returned the same live record through both managed service domains. |
| Firestore application tests | Three passed using the official local emulator, including idempotent seeding and the real query. |
| Backend Docker | Original AWS and new GCP backend images built. The GCP amd64 image was 66,190,367 bytes according to Docker image inspection and returned 200 from `/healthz` on an injected `PORT=8093`. |
| Existing AWS app regression | Private local PostgreSQL initialized via Alembic. Meeting GET, POST and agenda PUT returned the expected statuses and persisted fields. No AWS API or production deployment was invoked. |
| Frontend | Standard and public GCP Vite builds passed. ESLint and Prettier checks passed. The online npm audit found zero runtime dependency advisories and 14 reports in development dependencies. Those pre-existing dependencies were not changed as part of the migration. |
| GitHub Actions | [Branch lint passed](https://github.com/shlapakolesia/Spry/actions/runs/44351474863). Image publishing stayed gated and skipped. |
| Backend lint | Ruff passed for the backend and OCR script. |
| BigQuery | `spry-ucu-sandbox-2026-74cf` remains unbilled. A capped query produced [63 rows](evidence/bigquery-results.csv) and processed 169,627,794 bytes. [Job metadata](evidence/bigquery-job.json) is available. |
| Cloud Run | Ready revision `spry-lab-api-00001-s52`. Public [meetings endpoint](https://spry-lab-api-4zmigy2dba-uc.a.run.app/api/meetings) returned HTTP 200 and the real Firestore record. |
| Firebase Hosting | [Public frontend](https://spry-ucu-lab-2026-a83f.web.app/) and both static assets returned 200. The [Hosting rewrite](https://spry-ucu-lab-2026-a83f.web.app/api/meetings) returned the same JSON as Cloud Run. A private Chrome window rendered the seeded meeting without sign-in. The deployed Firestore rules deny direct client reads and writes. |
| Billing | Console still showed the Free Trial after linking, with $300 remaining and expiration February 17, 2027. The $5 monthly budget monitors this project before credits at 50%, 90%, and 100%. |
| Vision OCR | A real Cloud Vision text detection call recognized the synthetic receipt, including the USD 9.00 total. The genuine result is captured in `OCR.png`. |
| Data Studio | The private Data Studio report totals the 63 BigQuery CSV rows by name. The chart was verified in viewer mode and captured as `Looker_Studio.png`. |

The applied bootstrap includes regional Artifact Registry and the application APIs. The deployment guide shows how to restore the existing HCP connection from another checkout. There is no Cloud SQL instance or deployment secret. See [demo instructions](../gcp/demos/README.md) and the [cleanup runbook](../gcp/README.md#6-cleanup-after-grading).
