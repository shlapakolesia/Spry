"""Cloud Run entry point for the public, read-only lab."""

import logging
from typing import Annotated

from fastapi import Depends, FastAPI, HTTPException, Response
from google.api_core.exceptions import GoogleAPIError
from google.cloud import firestore
from pydantic import ValidationError

from app.firestore_meetings import PublicMeeting, get_firestore, list_meetings

app = FastAPI(title="Spry GCP lab", docs_url=None, redoc_url=None, openapi_url=None)
logger = logging.getLogger(__name__)


@app.get("/healthz")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/api/meetings", response_model=list[PublicMeeting])
def meetings(
    response: Response, client: Annotated[firestore.Client, Depends(get_firestore)]
) -> list[PublicMeeting]:
    try:
        records = list_meetings(client)
    except (GoogleAPIError, ValidationError) as error:
        logger.warning("Public meeting query failed (%s)", type(error).__name__)
        raise HTTPException(status_code=503, detail="Meetings are unavailable") from None
    # Only seeded public records are served. Short caching reduces repeated reads.
    response.headers["Cache-Control"] = "public, max-age=30, s-maxage=60"
    return records
