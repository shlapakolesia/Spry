import json
import logging
import time
from datetime import date
from typing import Any

import jwt
from anthropic import RateLimitError
from jwt import PyJWKClient
from jwt.exceptions import PyJWKClientError

from app.ai.agenda import PROMPT_VERSION, AgendaParseError, cost_usd, parse_agenda
from app.config import (
    COGNITO_CLIENT_ID,
    COGNITO_REGION,
    COGNITO_USER_POOL_ID,
    PARSER_MODEL,
)

logger = logging.getLogger()
logger.setLevel(logging.INFO)
ISSUER = f"https://cognito-idp.{COGNITO_REGION}.amazonaws.com/{COGNITO_USER_POOL_ID}"
JWKS = PyJWKClient(f"{ISSUER}/.well-known/jwks.json", cache_keys=True)


def _response(status: int, body: dict[str, Any] | None = None) -> dict[str, Any]:
    return {
        "statusCode": status,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(body or {}),
    }


def verify_cognito_token(authorization: str) -> str:
    if not isinstance(authorization, str) or not authorization.lower().startswith(
        "bearer "
    ):
        raise ValueError("missing bearer token")
    token = authorization.split(None, 1)[1]
    signing_key = JWKS.get_signing_key_from_jwt(token)
    claims = jwt.decode(
        token,
        signing_key.key,
        algorithms=["RS256"],
        issuer=ISSUER,
        audience=COGNITO_CLIENT_ID,
    )
    if claims.get("token_use") != "id" or not claims.get("sub"):
        raise ValueError("invalid Cognito token")
    return str(claims["sub"])


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    del context
    headers = {
        str(key).lower(): value for key, value in (event.get("headers") or {}).items()
    }
    if event.get("requestContext", {}).get("http", {}).get("method") == "OPTIONS":
        return _response(204)
    try:
        user = verify_cognito_token(headers.get("authorization", ""))
    except (ValueError, jwt.PyJWTError, PyJWKClientError):
        return _response(401, {"error": "Sign in to parse an agenda."})
    try:
        body = json.loads(event.get("body") or "{}")
        text = body["text"]
        if not isinstance(text, str):
            return _response(400, {"error": "Text is required."})
        if len(text) > 10_000:
            return _response(
                413, {"error": "Agenda text must be 10,000 characters or fewer."}
            )
        today = date.fromisoformat(body["today"])
        tz = body["tz"]
        if not isinstance(tz, str) or not tz:
            raise ValueError("timezone is required")
    except (ValueError, KeyError, TypeError, json.JSONDecodeError):
        return _response(400, {"error": "Send text, today's date, and a time zone."})

    started = time.monotonic()
    try:
        agenda, usage = parse_agenda(text, today, tz)
    except AgendaParseError as error:
        usage = error.usage
        logger.info(
            json.dumps(
                {
                    "event": "agenda_parsed",
                    "user": user,
                    "model": PARSER_MODEL,
                    "prompt_version": PROMPT_VERSION,
                    **usage,
                    "latency_ms": int((time.monotonic() - started) * 1000),
                    "cost_usd": cost_usd(PARSER_MODEL, usage),
                    "status": "parse_error",
                }
            )
        )
        return _response(422, {"error": str(error)})
    except RateLimitError:
        usage = {"input_tokens": 0, "output_tokens": 0}
        logger.info(
            json.dumps(
                {
                    "event": "agenda_parsed",
                    "user": user,
                    "model": PARSER_MODEL,
                    "prompt_version": PROMPT_VERSION,
                    **usage,
                    "latency_ms": int((time.monotonic() - started) * 1000),
                    "cost_usd": 0,
                    "status": "throttled",
                }
            )
        )
        return _response(
            429, {"error": "Too many requests. Please wait a moment and try again."}
        )
    except Exception:
        logger.exception("agenda_parse_failed")
        usage = {"input_tokens": 0, "output_tokens": 0}
        logger.info(
            json.dumps(
                {
                    "event": "agenda_parsed",
                    "user": user,
                    "model": PARSER_MODEL,
                    "prompt_version": PROMPT_VERSION,
                    **usage,
                    "latency_ms": int((time.monotonic() - started) * 1000),
                    "cost_usd": 0,
                    "status": "service_error",
                }
            )
        )
        return _response(
            503,
            {
                "error": "The agenda parser is busy. Please try again or enter it by hand."
            },
        )
    logger.info(
        json.dumps(
            {
                "event": "agenda_parsed",
                "user": user,
                "model": PARSER_MODEL,
                "prompt_version": PROMPT_VERSION,
                **usage,
                "latency_ms": int((time.monotonic() - started) * 1000),
                "cost_usd": cost_usd(PARSER_MODEL, usage),
            }
        )
    )
    return _response(
        200,
        {
            "agenda": agenda.model_dump(mode="json"),
            "model": PARSER_MODEL,
            "prompt_version": PROMPT_VERSION,
        },
    )


def handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    return lambda_handler(event, context)
