"""Submit exactly one small, non-sensitive image to Cloud Vision."""

import argparse
import base64
from pathlib import Path

import google.auth
from google.auth.transport.requests import AuthorizedSession


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("project")
    parser.add_argument("image", type=Path)
    args = parser.parse_args()
    if args.image.suffix.lower() not in {".png", ".jpg", ".jpeg"}:
        parser.error("Supply one PNG or JPEG.")
    if not 0 < args.image.stat().st_size <= 2_000_000:
        parser.error("Use one nonempty image up to 2 MB.")

    credentials, _ = google.auth.default(
        scopes=["https://www.googleapis.com/auth/cloud-platform"],
        quota_project_id=args.project,
    )
    with AuthorizedSession(credentials) as session:
        response = session.post(
            "https://vision.googleapis.com/v1/images:annotate",
            json={
                "requests": [{
                    "image": {"content": base64.b64encode(args.image.read_bytes()).decode()},
                    "features": [{"type": "TEXT_DETECTION"}],
                }]
            },
            timeout=30,
        )
    if not response.ok:
        error = response.json().get("error", {})
        raise SystemExit(f"Vision HTTP {response.status_code}: {error.get('message', 'request failed')}")
    result = response.json()["responses"][0]
    if "error" in result:
        raise SystemExit(f"Vision error: {result['error']['message']}")
    text = result.get("fullTextAnnotation", {}).get("text")
    if not text:
        raise SystemExit("Vision detected no text.")
    print("Cloud Vision API · TEXT_DETECTION")
    print(text)


if __name__ == "__main__":
    main()
