import csv
import io
from datetime import datetime, timedelta, timezone

from sqlalchemy import select

from app.database import SessionLocal
from app.models.meeting import Meeting


def _week_start(week: str) -> datetime:
    """
    Convert an ISO week such as '2026-W40'
    to Monday 00:00 UTC.
    """
    try:
        date = datetime.strptime(f"{week}-1", "%G-W%V-%u")
    except ValueError as exc:
        raise ValueError(
            "Week must use ISO format YYYY-Www, for example 2026-W40"
        ) from exc

    return date.replace(tzinfo=timezone.utc)


def _meeting_duration_hours(meeting: Meeting) -> float:
    duration = meeting.ends_at - meeting.starts_at
    return duration.total_seconds() / 3600


def _statistics(meetings: list[Meeting]) -> tuple[int, float]:
    meeting_count = len(meetings)

    total_duration_hours = sum(
        _meeting_duration_hours(meeting)
        for meeting in meetings
    )

    return meeting_count, total_duration_hours


def build_weekly_report(week: str) -> bytes:
    """
    Query meetings for one ISO week and return a CSV report.

    Example:
        build_weekly_report("2026-W40")
    """

    current_start = _week_start(week)
    current_end = current_start + timedelta(days=7)

    previous_start = current_start - timedelta(days=7)

    with SessionLocal() as session:
        meetings = list(
            session.scalars(
                select(Meeting)
                .where(
                    Meeting.starts_at >= previous_start,
                    Meeting.starts_at < current_end,
                )
                .order_by(Meeting.starts_at)
            )
        )

    previous_meetings = [
        meeting
        for meeting in meetings
        if previous_start <= meeting.starts_at < current_start
    ]

    current_meetings = [
        meeting
        for meeting in meetings
        if current_start <= meeting.starts_at < current_end
    ]

    current_count, current_hours = _statistics(current_meetings)
    previous_count, previous_hours = _statistics(previous_meetings)

    count_change = current_count - previous_count
    duration_change = current_hours - previous_hours

    longest_meetings = sorted(
        current_meetings,
        key=_meeting_duration_hours,
        reverse=True,
    )[:5]

    output = io.StringIO()
    writer = csv.writer(output)

    writer.writerow(["Weekly meetings report"])
    writer.writerow(["week", week])
    writer.writerow([])

    writer.writerow(
        [
            "metric",
            "current_week",
            "previous_week",
            "change",
        ]
    )

    writer.writerow(
        [
            "meeting_count",
            current_count,
            previous_count,
            count_change,
        ]
    )

    writer.writerow(
        [
            "total_duration_hours",
            f"{current_hours:.2f}",
            f"{previous_hours:.2f}",
            f"{duration_change:.2f}",
        ]
    )

    writer.writerow([])
    writer.writerow(["five_longest_meetings"])

    writer.writerow(
        [
            "title",
            "start",
            "duration_hours",
            "participants",
        ]
    )

    for meeting in longest_meetings:
        writer.writerow(
            [
                meeting.title,
                meeting.starts_at.isoformat(),
                f"{_meeting_duration_hours(meeting):.2f}",
                meeting.attendee_count,
            ]
        )

    return output.getvalue().encode("utf-8")
