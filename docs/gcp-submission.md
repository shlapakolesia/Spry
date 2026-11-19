# UCU Cloud Architecture Lab · submission

## Certifications

| Certification | Relevance | Course reference exam fee and duration |
|---|---|---|
| Google Cloud Digital Leader | Introductory cloud services, costs and operating concepts | $99 / 90 min |
| Google Cloud Generative AI Leader | Model choices, responsible AI and organizational use | $99 / 90 min |
| Google Associate Cloud Engineer | Closest student match for Parts 0–2, covering IAM, deployment and operations | $125 / 2 h |
| Google Associate Data Practitioner | Best match for the BigQuery, Dataflow and reporting work in Part 4 and Lab 8 | $125 / 2 h |
| Google Professional Cloud Architect | Design, trade-offs, operations and case studies. Best after more hands-on work. | $200 / 2 h |
| Google Professional Data Engineer and Professional Machine Learning Engineer | Advanced specialist paths for the analytics and AI topics | $200 / 2 h each |
| AWS Certified Cloud Practitioner | AWS platform vocabulary and billing foundations | $100 / 90 min |
| AWS Certified Solutions Architect – Associate | AWS-side application design and trade-offs | $150 / 130 min |
| OCI Multicloud Architect Associate | Relevant to multi-cloud design and course bonus | Check Oracle Bridge voucher eligibility |

Provider rates and formats vary. Verify before booking. Use free learning resources from [Google Skills](https://www.skills.google/), [AWS Educate](https://aws.amazon.com/education/awseducate/), and [Oracle University](https://education.oracle.com/oracle-certification). [Google exam guides](https://cloud.google.com/learn/certification) and [AWS exam guides](https://aws.amazon.com/certification/) describe current scope. AWS lists a 50% subsequent-exam discount among [certification benefits](https://aws.amazon.com/certification/benefits/).

A certification tests breadth, vocabulary and judgment against a provider's exam objectives. It does not demonstrate that the candidate migrated a live workload, diagnosed an outage, or kept the bill within budget. Expiry and renewal requirements vary. Start with free Associate Cloud Engineer preparation for this lab. Under the supplied UCU course rules the bonus is **+10 points for one eligible certification**. Oracle exams through the Bridge program depend on the course's voucher allocation. Other certifications require the lecturer's written approval before the exam. No exam was booked or purchased.

## Submission checklist

- [x] Terraform and ADR are pushed to [GitHub branch lab-gcp](https://github.com/shlapakolesia/Spry/tree/lab-gcp).
- [x] Verify the [Cloud Run meetings endpoint](https://spry-lab-api-4zmigy2dba-uc.a.run.app/api/meetings) against live Firestore.
- [ ] Add the Firebase HTTPS URL after project registration and rewrite verification.
- [x] Include the [architecture decision](adr/aws-to-gcp-migration.md) and [four-profile costs](gcp-cost-comparison.md).
- [x] BigQuery and Vision OCR screenshots are saved in the Desktop submission folder.
- [ ] Attach the Looker Studio screenshot after completing [Data Studio setup](../gcp/demos/README.md#b-looker-studio-now-data-studio).
- [ ] Keep the environment for grading as needed. Then follow the [cleanup guide](../gcp/README.md#6-cleanup-after-grading).

## Ready-to-paste summary

> I implemented a separate Google Cloud configuration for Spry's public meeting list. Cloud Run serves the read-only FastAPI endpoint, and Firestore Native stores seeded sample meetings. The React frontend is built for Firebase Hosting. The AWS PostgreSQL app, Cognito sign-in, weekly reports and agenda parser remain on AWS. GCP Terraform state is separate. The ADR maps the services and documents the data model change. The cost analysis projects $0 billed for class traffic if the available ongoing free quotas cover usage.
>
> Commit: [insert pushed commit URL]. Frontend: [insert verified Firebase URL]. API: https://spry-lab-api-4zmigy2dba-uc.a.run.app/api/meetings. Attach the real BigQuery results screenshot, Looker Studio chart and Vision OCR screenshot after capturing them. Use the status in the [verification record](gcp-verification.md) to distinguish local checks from live results.
