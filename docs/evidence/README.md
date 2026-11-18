# Lab evidence

Keep the three real screenshots here as `bigquery.png`, `looker-studio.png`, and `vision-ocr.png`. The [demo guide](../../gcp/demos/README.md) maps each screenshot to the steps and the expected content.

- The [BigQuery job](bigquery-job.json) completed in the unbilled sandbox. It returned [63 rows](bigquery-results.csv) and processed 169,627,794 bytes. A console screenshot is pending.
- Looker Studio needs a browser session and the BigQuery output.
- Vision OCR needs a billing-enabled approved project and one small, non-sensitive image.

[Firestore API response](firestore-api.json) records a local FastAPI test client reading the live, unbilled Google Cloud Firestore database. Cloud Run and Firebase Hosting remain pending.
