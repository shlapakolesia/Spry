# UCU lab · Data and AI demonstrations

## A. BigQuery sandbox

The lab uses an unbilled project, `spry-ucu-sandbox-2026-74cf`. The [BigQuery sandbox](https://cloud.google.com/bigquery/docs/sandbox) includes 1 TiB queried and 10 GiB stored per month. Tables created in the sandbox expire after 60 days. The query totals annual US Social Security name records for Emma, Olivia and Sophia in the source category F from 2000 to 2020. It illustrates grouped time series with names changing popularity. The source's suppression rules and coverage limit what the counts represent.

The completed job returned 63 rows, processed 169,627,794 bytes, and recorded 169,869,312 bytes in the bytes-billed field. That field is BigQuery billing-unit metadata. The project was unbilled and the job was within sandbox quota. See the [job metadata](../../docs/evidence/bigquery-job.json) and [CSV result](../../docs/evidence/bigquery-results.csv).

To reproduce in a project you can access, sign in to Cloud Console → BigQuery Studio and select the unbilled sandbox project. Open a new SQL query tab, paste [usa_names.sql](bigquery/usa_names.sql), check the validator's estimate, and set More → Query settings → Advanced options → Maximum bytes billed to 209715200. Run the query. Save a screenshot showing SQL and the Results table. Open Job information and capture bytes processed if it does not fit in the same screenshot. Save them under `docs/evidence/bigquery.png` and optionally `docs/evidence/bigquery-job.png`.

```bash
export SPRY_BQ_PROJECT=spry-ucu-sandbox-2026-74cf
gcloud billing projects describe "$SPRY_BQ_PROJECT" --format='value(billingEnabled)'
bq --project_id="$SPRY_BQ_PROJECT" --location=US query --use_legacy_sql=false --dry_run < gcp/demos/bigquery/usa_names.sql
bq --project_id="$SPRY_BQ_PROJECT" --location=US --format=csv query \
  --use_legacy_sql=false --maximum_bytes_billed=209715200 --max_rows=100 \
  < gcp/demos/bigquery/usa_names.sql > /tmp/spry-bq-usa-names.csv
```

## B. Looker Studio (now Data Studio)

Use the [actual BigQuery CSV](../../docs/evidence/bigquery-results.csv) as a snapshot. The direct BigQuery connector requires a billing account, so use the free [file upload connector](https://docs.cloud.google.com/data-studio/upload-csv-files) or import the CSV into a private Google Sheet and select the Google Sheets connector. This avoids a billing dependency for a 63-row chart.

1. Open [Data Studio](https://datastudio.google.com/) → Create → Report. Choose File Upload, upload the CSV and add it to the report. Complete first-use account prompts if shown.
2. In the data source schema set `year` to a non-aggregated number, `name` to text, and `recorded_count` to a number with SUM aggregation.
3. Add a line chart. Set dimension to `year`, breakdown dimension to `name`, metric to SUM of `recorded_count`, sort to `year` ascending, and name it **US births recorded for Emma, Olivia and Sophia, 2000–2020**. Use a visible legend and a y-axis labeled “Recorded count.”
4. Click View, check all three series, and capture the full chart. Save `docs/evidence/looker-studio.png`. Keep the source and report private unless the course requests sharing.

## C. Cloud Vision OCR

[Cloud Vision](https://cloud.google.com/vision/pricing) recognizes text with one `TEXT_DETECTION` feature request. The first 1,000 units/month are free. The next tier is $1.50/1,000 units. [Billing must be enabled](https://cloud.google.com/vision/docs/before-you-begin), even for an expected zero-charge request. Use the billing-linked lab project only after approval. No Cloud Storage bucket is needed.

Write a synthetic note on one page, for example “Spry lab / Review migration / Monday 14:00”, and photograph it in good light. Use one PNG/JPEG no larger than 2 MB, with no personal details. Check the project's usage is within the free allowance. Run from the repo root after [creating the Python environment](../README.md).

```bash
gcloud services enable vision.googleapis.com --project="$SPRY_GCP_PROJECT"
backend/.venv/bin/python gcp/demos/ocr/vision_ocr.py "$SPRY_GCP_PROJECT" /path/to/spry-note.jpg
```

Capture the terminal showing the command and recognized text, without credentials or unrelated terminal history. Save `docs/evidence/vision-ocr.png`. Document the recognized text and any errors. Enterprise Document OCR and Form Parser are different Document AI SKUs. At the assignment's example $30 per 1,000, one Form Parser page is $0.03 at the marginal rate. It was excluded from the demo.

## Other services and Lab 8

| Google Cloud | AWS counterpart | Role |
|---|---|---|
| BigQuery | Athena / Redshift Serverless | Run SQL over payment data. Native BigQuery tables remove the need for a separate Athena database and Glue crawler for that data. |
| Dataflow | Glue ETL / Managed Service for Apache Flink | Apache Beam worker service for batch transforms and streaming. Transform or load the Cloud Storage equivalent of the Lab 8 S3 payment files. |
| Looker Studio | QuickSight | Visualize query or extracted data. The report can be a thin layer on top of the SQL result. |
| Looker | QuickSight Enterprise | Shared governed measures and joins through LookML. Enterprise licensing is unnecessary for the student chart. |
| Managed Service for Apache Airflow | Amazon MWAA | Orchestrate ingestion, transformations and refreshes in DAGs. Provisioned environments have a standing cost. |
| Vertex AI Gemini and Model Garden | Bedrock | LLM inference for agenda structuring and inference evaluation. Model and token prices vary. The AI Studio free quota is a separate product surface. No verified Vertex AI free allowance was available for this run. |
| Veo | Amazon Nova Reel | Generate video. Per-second pricing makes clip length a cost driver. No generation was submitted. |
| Vision / Document AI | Textract for OCR and structured forms | Use specialized OCR when bounding boxes, layout, extraction consistency or exact transcription matter. Use an LLM for ambiguous agenda language or schema reasoning, then validate its output. |

The Lab 8 flow maps S3 payments → Cloud Storage, Glue ETL/crawler → Dataflow and curated BigQuery tables, Athena → BigQuery SQL, and charts → Looker Studio. BigQuery removes query-cluster management and a separate crawler/catalog for native tables. A direct load job can handle a clean tiny CSV with fewer operational steps than Dataflow. Pricing sources include [BigQuery](https://cloud.google.com/bigquery/pricing), [Dataflow](https://cloud.google.com/dataflow/pricing), [Looker](https://cloud.google.com/looker/pricing), [Airflow](https://cloud.google.com/composer/pricing), [Vertex AI and Veo](https://cloud.google.com/vertex-ai/generative-ai/pricing), and [Document AI](https://cloud.google.com/document-ai/pricing).

### Optional Dataflow exercise · prepared only

The [Cloud Storage Text to BigQuery batch template](https://docs.cloud.google.com/dataflow/docs/guides/templates/provided/cloud-storage-to-bigquery) needs a billed project, an initialized US BigQuery dataset named `spry_demos`, a same-region bucket, enabled Dataflow and Compute APIs, and a dedicated worker identity with Dataflow Worker plus required BigQuery dataset, BigQuery job and bucket access. An operator needs permission to run jobs and act as that identity. For one worker with 1 vCPU and 3.75 GiB for ten minutes at Iowa rates, compute and memory are roughly `(0.056 + 3.75 × 0.003557) / 6 = $0.0116`. Disk, shuffle, staging, private networking if used and worker startup or a longer run can add costs. This example was not run. Obtain approval for its charges before running it.

```bash
export SPRY_BUCKET="gs://$SPRY_GCP_PROJECT-dataflow"
export SPRY_DATAFLOW_SA="spry-df-worker@$SPRY_GCP_PROJECT.iam.gserviceaccount.com"
gcloud storage cp gcp/demos/dataflow/{meetings.csv,schema.json,transform.js} "$SPRY_BUCKET/input/"
gcloud dataflow flex-template run spry-meetings-demo --project="$SPRY_GCP_PROJECT" --region=us-central1 \
  --template-file-gcs-location=gs://dataflow-templates/latest/flex/GCS_Text_to_BigQuery_Flex \
  --service-account-email="$SPRY_DATAFLOW_SA" --num-workers=1 --max-workers=1 \
  --worker-machine-type=e2-standard-2 --staging-location="$SPRY_BUCKET/staging" \
  --parameters="inputFilePattern=$SPRY_BUCKET/input/meetings.csv,JSONPath=$SPRY_BUCKET/input/schema.json,outputTable=$SPRY_GCP_PROJECT:spry_demos.meetings,javascriptTextTransformGcsPath=$SPRY_BUCKET/input/transform.js,javascriptTextTransformFunctionName=transform,bigQueryLoadingTemporaryDirectory=$SPRY_BUCKET/bq-temp"
```

The command's two-vCPU worker can cost more than the per-small-worker illustration. At 2 vCPU and 8 GiB for ten minutes the same compute/memory calculation is about $0.0234 before other SKUs. Watch the job to completion in Dataflow → Jobs. Verify one output row and remove the temporary table, objects and demo resources after evidence collection.
