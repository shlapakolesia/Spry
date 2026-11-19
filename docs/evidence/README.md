# Lab evidence

- The [BigQuery job](bigquery-job.json) completed in the unbilled sandbox. It returned [63 rows](bigquery-results.csv) and processed 169,627,794 bytes. The console screenshot showing the SQL and results is saved as `BigQuery.png` in the Desktop submission folder.
- Cloud Vision recognized the synthetic receipt, including its USD 9.00 total. A genuine screenshot of the returned text is saved as `OCR.png` in the Desktop submission folder.
- Data Studio charted the exported BigQuery CSV as totals by name across 2000–2020. `Looker_Studio.png` in the Desktop submission folder shows the actual report in viewer mode.
- [Firestore API response](firestore-api.json) records HTTP 200 from the deployed Cloud Run API reading the live default Firestore database.

The [demo guide](../../gcp/demos/README.md) describes how to reproduce the evidence.
