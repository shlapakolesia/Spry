import json
import logging
import os
from datetime import date, timedelta

import boto3

from app.reports.weekly import build_weekly_report

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")


def _previous_iso_week() -> str:
    today = date.today()

    current_monday = today - timedelta(days=today.weekday())
    previous_week_day = current_monday - timedelta(days=7)

    iso_year, iso_week, _ = previous_week_day.isocalendar()

    return f"{iso_year}-W{iso_week:02d}"


def _parse_event(event: dict) -> tuple[str | None, str]:
    """
    Support:
    1. direct Scheduler event:
       {"source": "schedule"}

    2. SQS event whose body contains:
       {"week": "2026-W40", "source": "sqs"}
       or
       {"week": null, "source": "schedule"}
    """

    records = event.get("Records")

    if records:
        record = records[0]

        if record.get("eventSource") == "aws:sqs":
            body = json.loads(record["body"])

            week = body.get("week")
            source = body.get("source", "sqs")

            return week, source

    return event.get("week"), event.get("source", "direct")


def handler(event, context):
    week, source = _parse_event(event)

    if not week:
        week = _previous_iso_week()

    event_source = "sqs" if event.get("Records") else "direct"

    logger.info(
        "trigger=%s event_source=%s week=%s",
        source,
        event_source,
        week,
    )

    reports_bucket = os.environ["REPORTS_BUCKET"]

    report = build_weekly_report(week)

    key = f"reports/{week}.csv"

    s3.put_object(
        Bucket=reports_bucket,
        Key=key,
        Body=report,
        ContentType="text/csv; charset=utf-8",
    )

    logger.info(
        "report_saved bucket=%s key=%s",
        reports_bucket,
        key,
    )

    return {
        "statusCode": 200,
        "week": week,
        "bucket": reports_bucket,
        "key": key,
    }
