# ADR 0008 · Move Spry's public meeting list to Google Cloud

**Status:** Selected and deployed for the lab. Cloud Run and Firestore are live on the verified Free Trial. Firebase Hosting awaits project registration.

The AWS checkout uses Python/FastAPI, SQLAlchemy and PostgreSQL. Alembic 0001 creates meetings and 0002 adds agenda and AI suggestion JSON. Compose migrates with `alembic upgrade head`. `GET /api/meetings` orders by start time and ID, `POST` creates a meeting, and `PUT /api/meetings/{id}/agenda` persists the agenda. The React/Vite frontend uses relative URLs and Cognito through OIDC. `infra/` manages the imported authentication, report and parser resources in HCP workspace `spry-dev`. The API, database, frontend edge and registry are outside that state. CI publishes ECR images and S3 assets. The Makefile's API rollout targets ECS, while the assignment models an alternate Lambda-based stage. The actual database instance settings and edge pricing plan require an AWS inventory or billing export to confirm.

| AWS in Spry | GCP counterpart | Decision | Reason, cost and trade-off |
|---|---|---|---|
| S3 frontend + CloudFront, WAF in the lab reference | Firebase Hosting | REPLACE | Managed HTTPS and CDN, with storage/transfer allowances. The same-project rewrite requires Blaze and can incur overages. No dedicated WAF or load balancer is added. |
| ECS deploy target for the main FastAPI API, plus function URLs on auxiliary Lambda endpoints | Cloud Run | REPLACE | Serve the meetings slice with Uvicorn and request billing. Scale to zero reduces idle compute and introduces cold starts. |
| ECR image repository | Artifact Registry | REPLACE | Same Docker workflow, regional repository, 0.5 GB free at billing-account level. Old image layers consume storage until deleted. |
| PostgreSQL via SQLAlchemy, Aurora in the lab reference | Firestore Native | REPLACE | Default database has daily operation quotas and no instance charge. The public meeting projection has no relational edits or migrations. |
| DynamoDB absent in repository | Firestore | DROP | No DynamoDB data or calls to migrate, and no second database to provision. |
| Cognito with Google OIDC and fixed AWS callback | Firebase Authentication / Identity Platform | KEEP | The AWS UI keeps its sign-in. The GCP read-only page has no sign-in or user data. No second identity store or MAU exposure. |
| Scheduler sends weekly report requests | Cloud Scheduler | KEEP | Avoid duplicating the existing schedule or sending a second report. |
| SQS report queue + DLQ | Cloud Tasks / Pub/Sub | KEEP | Preserve retry and dead-letter semantics. A GCP migration must define delivery, idempotency and dead-letter behavior separately. |
| Report bucket creation event invokes mailer Lambda | Cloud Storage + Eventarc | KEEP | Preserve current report lifecycle and avoid duplicate triggers, storage and events. |
| SES report mailer with IAM | SES | KEEP | The existing role authorizes SES with short-lived credentials and needs no API key. If a later GCP mailer uses an external transactional provider, scope its API key and store it in Secret Manager. |
| Bedrock Mantle agenda parser Lambda | Vertex AI | KEEP | Retain Cognito access controls and evaluated prompts. Token prices, partner eligibility and output quality require independent testing. |
| HCP sensitive variables for existing AWS configuration. SSM/Secrets Manager are lab reference patterns. | Secret Manager | DROP for GCP core | Firestore uses runtime identity with no database password. Retain AWS sensitive variable handling. |
| CloudWatch | Cloud Logging | REPLACE | Cloud Run captures request and application logs. Keep payloads and credentials out of logs and monitor ingestion. |
| Lambda execution roles and AWS deployment OIDC | Service accounts and WIF | REPLACE | Separate runtime read, Terraform deploy and CI repository writer permissions without keys. |
| AWS provider and HCP `spry-dev` | Google provider with separate roots/state | REPLACE | Limit blast radius. Firebase release steps and initial billing are explicit, separate operations. |

## Database decision

| Option | Out-of-pocket and risk | Compatibility, latency and operations |
|---|---|---|
| Default Firestore in Iowa | Expected $0 for the lab within permanent quota. Excess reads, storage and egress can bill with billing enabled. | Accepted by the assignment. Minimal standalone read adapter reuses the meetings URL and meeting display fields. Same region as Run avoids cross-cloud hops. One seed document and indexed ordering by start time. Easy to tear down in a dedicated project. |
| 30-day Cloud SQL PostgreSQL product trial | Free instance and instance storage in a new billing-enabled project. Internet or cross-region transfers and a final backup can bill. Account/project eligibility was not tested. | Keeps the PostgreSQL schema and Alembic, but preset configuration and Cloud SQL networking/auth setup add steps. Creation is documented via Console; normal `google_sql_database_instance` creation does not select this trial. Trial import/lifecycle management was not verified. Serving stops after 30 days and data is retained for a 90-day grace period unless upgraded or deleted. |
| Regular Cloud SQL using signup credits | Retail charges accrue and may consume the temporary credit, if eligible. Cash can be due after credit expiry or exhaustion on a paid account. | Best PostgreSQL compatibility and Terraform reproducibility. Continuous compute and storage remain even between demos; stopping interrupts service and leaves storage billed. |
| PostgreSQL retained on AWS | Keeps AWS compute/storage plus possible cross-cloud connectivity and transfer charges. | Least schema work, highest operational/network coordination. Keep PostgreSQL private and use authenticated private connectivity. Wider round trips and wake-ups can dominate latency and keep Aurora active. |

Firestore has no SQL joins, foreign keys, auto-incrementing sequences or Alembic migration path. The dedicated Cloud Run entry point uses ADC and a typed, bounded query. Firestore timestamps preserve the time range and the document uses a stable seeded ID. The frontend builds into a public read-only mode using the existing meeting card. Inserts, updates, reports, agenda parsing and real AWS data remain on AWS. The GCP project contains only intentionally public synthetic data. The seed command is an authenticated operator action. Firestore's viewer role is project-scoped, so the project must remain dedicated to this lab.

Cold starts and CDN/cache misses can add latency. The Firebase rewrite keeps the browser on one origin and the Firestore query stays regional. No latency has been measured on GCP. Estimated monthly class usage is $0 conditional on free quotas and account eligibility. See the [cost comparison](../gcp-cost-comparison.md), [Google free program](https://cloud.google.com/free/docs/free-cloud-features), and [Cloud SQL trial terms](https://cloud.google.com/sql/docs/postgres/free-trial-instance).
