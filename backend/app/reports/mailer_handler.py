import logging
import os
from email.message import EmailMessage
from urllib.parse import unquote_plus

import boto3


logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")
ses = boto3.client("ses")


def handler(event, context):
    records = event.get("Records", [])

    for record in records:
        if record.get("eventSource") != "aws:s3":
            logger.warning("Unsupported event: %s", record)
            continue

        bucket = record["s3"]["bucket"]["name"]
        key = unquote_plus(record["s3"]["object"]["key"])

        logger.info(
            "trigger=s3 event_source=s3 bucket=%s key=%s",
            bucket,
            key,
        )

        if not key.startswith("reports/") or not key.endswith(".csv"):
            logger.info("Ignoring object outside reports/*.csv: %s", key)
            continue

        response = s3.get_object(
            Bucket=bucket,
            Key=key,
        )

        report_bytes = response["Body"].read()

        filename = key.rsplit("/", 1)[-1]

        report_email = os.environ["REPORT_EMAIL"]

        message = EmailMessage()
        message["Subject"] = f"Spry weekly report: {filename}"
        message["From"] = report_email
        message["To"] = report_email

        message.set_content(
            "Your Spry weekly meetings report is attached."
        )

        message.add_attachment(
            report_bytes,
            maintype="text",
            subtype="csv",
            filename=filename,
        )

        result = ses.send_raw_email(
            Source=report_email,
            Destinations=[report_email],
            RawMessage={
                "Data": message.as_bytes(),
            },
        )

        logger.info(
            "email_sent message_id=%s key=%s",
            result["MessageId"],
            key,
        )

    return {
        "statusCode": 200,
        "processedRecords": len(records),
    }
