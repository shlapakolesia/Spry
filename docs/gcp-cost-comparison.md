# Spry monthly cost comparison

USD list-price estimates, excluding tax, using a 730-hour month and the lab's comparison regions, N. Virginia and Iowa. Official pricing pages consulted 18 November 2026. The checkout targets AWS `eu-north-1` and ECS in the Makefile. The main database and live task configuration are outside `infra/`, so the AWS rows model the lab's Aurora/Lambda baseline and show an ECS sensitivity separately. This is an estimate for the Spry meetings workload, not an AWS billing export. The [AWS](https://calculator.aws/) and [Google Cloud](https://cloud.google.com/products/calculator) calculators were not used to produce these totals. The line items below can be entered there with the same assumptions.

## Workload and rates

Assume 60 page/API requests an hour, one request per visit, 150 ms billable request time, 0.2 MB of frontend transfer per visit (repeated visitors may fetch less), 2 KB per API response, 1 KB logs per request, and one Firestore document read per call. Do not count any cache savings. Assume two Aurora billed I/Os per request, 1 GB of Aurora storage, 1.5 GB of private ECR layers, one 0.15 GiB GCP image, 0.01 GB Hosting storage including retained releases and 0.001 GiB Firestore data and indexes. The traffic cases use 0, 20, 176 and 730 hours. Active Aurora uses 0.5 ACU and a five-minute pause tail for each scheduled session or office day. One writer, no read replicas. The busy case keeps Aurora awake throughout. Cold starts, AWS baseline idle logs, Cloud Run startup, Firestore seed writes, backups and varying on-demand utilization are unmeasured. For the busy row assume visits are spread through the month.

| Line item and rates | Idle | 10 × 2 h | 8 h × 22 days | Busy 24/7 |
|---|---:|---:|---:|---:|
| API requests | 0 | 1,200 | 10,560 | 43,800 |
| Frontend transfer, GB | 0 | 0.240 | 2.112 | 8.760 |
| Aurora hours including tail | 0 | 20.833 | 177.833 | 730 |
| AWS CloudFront Free + associated S3 storage/requests, WAF and HTTPS, assumed within plan | 0 | 0 | 0 | 0 |
| AWS Lambda x86 at 512 MiB, $0.20/M requests + $0.0000166667/GiB-s, gross | 0 | 0.0017 | 0.0153 | 0.0635 |
| Aurora Standard compute, $0.12/ACU-h | 0 | 1.2500 | 10.6700 | 43.8000 |
| Aurora storage $0.10/GB + $0.20/M I/Os | 0.1000 | 0.1005 | 0.1042 | 0.1175 |
| ECR, $0.10/GB, no temporary allowance modeled | 0.1500 | 0.1500 | 0.1500 | 0.1500 |
| CloudWatch ingestion at $0.50/GB, gross | 0 | 0.0006 | 0.0053 | 0.0219 |
| AWS secrets and other incremental services | 0 | 0 | 0 | 0 |
| **AWS gross, with retail $0 CDN plan** | **0.2500** | **1.5028** | **10.9448** | **44.1529** |
| AWS Lambda / CloudWatch deduction | 0 | -0.0023 | -0.0206 | -0.0854 |
| **AWS billed before credits** | **0.25** | **1.50** | **10.92** | **44.07** |
| Firebase storage $0.026/GB, CDN transfer $0.15/GB, HTTPS included, gross before allowance | 0.0003 | 0.0363 | 0.3171 | 1.3143 |
| Cloud Run $0.000024/vCPU-s + $0.0000025/GiB-s + $0.40/M requests, gross | 0 | 0.0049 | 0.0432 | 0.1793 |
| Firestore instance compute ($0) and storage at $0.15/GiB, gross | 0.0002 | 0.0002 | 0.0002 | 0.0002 |
| Firestore reads at $0.03/100k, gross | 0 | 0.0004 | 0.0032 | 0.0131 |
| Artifact Registry $0.10/GiB, gross | 0.0150 | 0.0150 | 0.0150 | 0.0150 |
| Cloud Logging ingestion $0.50/GiB, approximate gross | 0 | 0.0006 | 0.0053 | 0.0219 |
| Cloud Run API transfer sensitivity at $0.12/GB, gross upper estimate for this model | 0 | 0.0003 | 0.0025 | 0.0105 |
| Secret Manager, jobs, load balancer and optional demos in hosting model | 0 | 0 | 0 | 0 |
| **GCP gross at overage rates** | **0.02** | **0.06** | **0.39** | **1.55** |
| GCP permanent allowances, conditional | -0.02 | -0.06 | -0.39 | -1.55 |
| **GCP billed before credits** | **0.00** | **0.00** | **0.00** | **0.00** |
| Promotional or trial credits applied | 0 | 0 | 0 | 0 |
| **Cheaper under these assumptions** | **GCP** | **GCP** | **GCP** | **GCP** |

For example the class compute line on AWS is `(20 + 10 × 5/60) × 0.5 × $0.12`. The class Cloud Run line uses `1200 × (0.15 × ($0.000024 + 0.25 × $0.0000025) + $0.40/1000000)`. The frontend transfer row models static assets only. Firebase limits also apply to rewrites. Even counting the API bytes again against the Hosting allowance leaves this traffic profile within it. AWS model assumes same-region origin transfers and no billable external transfer, IP address, NAT gateway, ALB, Route 53 zone or separate WAF plan. If S3 is billed separately, at $0.023/GB-month and $0.0004/1,000 GETs the storage is under one cent and even 43,800 origin reads add about $0.018. Cognito, report and parser costs continue on AWS and cancel as unchanged costs of the migration. Their actual Invocations/SES recipients/model tokens are unknown. If the current ECS deployment actually runs one continuous Linux/x86 Fargate task at 0.25 vCPU and 0.5 GB, add **$9.01/month** to the AWS totals under the lab region rates after replacing the $0 billed Lambda line. Add any load balancer, public IP or other network charges separately. This is a sensitivity case.

AWS includes 1M Lambda requests and 400,000 GiB-s plus 5 GB of CloudWatch log allowance at this scale. Verify that the distribution is actually enrolled in the CloudFront Free plan. GCP request-based Run allowances are 2M requests, 180,000 vCPU-s and 360,000 GiB-s, with 1 GiB/month free transfer within North America where applicable. International or direct API traffic may bill. Firebase lists daily Blaze transfer allowance of 360 MB on its pricing table and 10 GB/month in Hosting usage documentation. Class plans and the modeled even traffic fit both. Firestore has one free database per project, 50,000 reads, 20,000 writes and 20,000 deletes per day, plus 1 GiB data and 10 GiB outbound/month. Registry allowance is 0.5 GiB per shared billing account and Cloud Logging allowance is 50 GiB per project. Monthly and daily caps are conditional on other usage and geography. Charges can follow aggressive polling, image retention, scans, and broad listing queries. Budget alerts send email and do not stop requests. Terraform's one-instance limit is a capacity setting. Even one fully active 1-vCPU instance for 730 hours approaches $59 CPU and $0.74 RAM after these allowances, plus requests and other SKUs.

## Database cost and risk

- **Running Cloud SQL** costs about **$9.37/month** in the lab's Iowa shared-core configuration (`730 × $0.0105 + 10 × $0.17`) before backups, networking and any other resources. It does not self-pause. This is the closest GCP equivalent of Aurora being kept awake, and it bills compute even during idle traffic.
- **Stopped Cloud SQL** still costs **$1.70/month** for the modeled SSD, before backup and other retained costs. If started only for 20 / 176 / 730 hours, the corresponding base totals are **$1.91 / $3.55 / $9.37**. The API would be unavailable between sessions.
- **Firestore** has no idle compute and charges for operations and storage beyond quota. Its read/write/delete marginal example rates in Iowa are $0.03/$0.09/$0.01 per 100,000, with storage about $0.15/GiB-month. TTL, backups, restores and PITR can bill independently. At the seeded cardinality, the persistence line drives the cloud difference when Aurora stays awake. Even at idle Aurora storage and ECR are the residual drivers. A keep-alive or pinned DB session can cause continued Aurora compute and its cost is approximately $43.80 at 0.5 ACU through the modeled month.
- **AWS PostgreSQL shared across clouds** retains the AWS database bill and can add private connectivity, gateway and transfer costs. The extra hop increases latency and a remote connection pool can keep Aurora awake. No public database access is required for this lab.
- **Cloud SQL product trial** is a distinct 30-day instance offer with billable exceptions. **Signup credits** are temporary and distinct from recurring quotas. Neither was used.

No billing-linked stack was deployed. Two dedicated unbilled projects exist. The application project contains the default Firestore database and one seed record. The other project ran the BigQuery sandbox query. Expected cash for the proposed student stack is $0 under the class assumptions and available allowances. Forecast and actual spend must be checked in Billing → Reports after any approved deployment.

## Pricing references

- AWS [Aurora](https://aws.amazon.com/rds/aurora/pricing/), [auto-pause](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2-auto-pause.html), [Fargate](https://aws.amazon.com/fargate/pricing/), [Lambda](https://aws.amazon.com/lambda/pricing/), [ECR](https://aws.amazon.com/ecr/pricing/), [CloudFront plans](https://aws.amazon.com/cloudfront/pricing/), [S3](https://aws.amazon.com/s3/pricing/), [CloudWatch](https://aws.amazon.com/cloudwatch/pricing/).
- Google [free quotas](https://cloud.google.com/free/docs/free-cloud-features), [Cloud Run](https://cloud.google.com/run/pricing), [Firestore](https://cloud.google.com/firestore/pricing), [Firebase Hosting](https://firebase.google.com/docs/hosting/usage-quotas-pricing), [Firebase rates](https://firebase.google.com/pricing), [Artifact Registry](https://cloud.google.com/artifact-registry/pricing), [Logging](https://cloud.google.com/products/observability/pricing), [Cloud SQL](https://cloud.google.com/sql/pricing), [Cloud SQL trial](https://cloud.google.com/sql/docs/postgres/free-trial-instance).
