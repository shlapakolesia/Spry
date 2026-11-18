"""Read and seed the public Spry lab meeting collection."""

import argparse
import os
from datetime import UTC, datetime
from functools import lru_cache

from google.cloud import firestore
from pydantic import AwareDatetime, BaseModel, Field, model_validator

COLLECTION = "lab_meetings"
LIST_LIMIT = 20


class PublicMeeting(BaseModel):
    id: int = Field(gt=0)
    title: str = Field(min_length=1, max_length=200)
    starts_at: AwareDatetime
    ends_at: AwareDatetime
    attendee_count: int = Field(ge=0)

    @model_validator(mode="after")
    def check_times(self) -> "PublicMeeting":
        if self.ends_at <= self.starts_at:
            raise ValueError("ends_at must be strictly after starts_at")
        return self


@lru_cache(maxsize=1)
def get_firestore() -> firestore.Client:
    return firestore.Client(project=os.environ["SPRY_GCP_PROJECT"], database="(default)")


def list_meetings(client: firestore.Client) -> list[PublicMeeting]:
    documents = (
        client.collection(COLLECTION)
        .order_by("starts_at")
        .limit(LIST_LIMIT)
        .stream(timeout=5)
    )
    return [PublicMeeting.model_validate(document.to_dict()) for document in documents]


def seed(client: firestore.Client) -> None:
    meeting = PublicMeeting(
        id=1,
        title="Spry cloud architecture walkthrough",
        starts_at=datetime(2026, 11, 23, 14, tzinfo=UTC),
        ends_at=datetime(2026, 11, 23, 15, tzinfo=UTC),
        attendee_count=6,
    )
    client.collection(COLLECTION).document(str(meeting.id)).set(meeting.model_dump())


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Write one public example meeting")
    parser.add_argument("--confirm-project", required=True)
    args = parser.parse_args()
    if args.confirm_project != os.environ.get("SPRY_GCP_PROJECT"):
        parser.error("--confirm-project must match SPRY_GCP_PROJECT")
    seed(get_firestore())
    print("Seeded lab_meetings/1.")
