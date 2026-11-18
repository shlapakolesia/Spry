import os
import unittest
from unittest.mock import Mock

from app.firestore_meetings import get_firestore, list_meetings, seed
from app.gcp_main import app
from fastapi.testclient import TestClient
from google.api_core.exceptions import ServiceUnavailable


class MeetingsTest(unittest.TestCase):
    def setUp(self):
        self.database = Mock()
        self.collection = self.database.collection.return_value
        self.query = self.collection.order_by.return_value.limit.return_value
        app.dependency_overrides[get_firestore] = lambda: self.database
        self.addCleanup(app.dependency_overrides.clear)
        self.http = TestClient(app)
        self.addCleanup(self.http.close)

    def test_seed_and_bounded_read(self):
        seed(self.database)
        self.database.collection.assert_called_with("lab_meetings")
        self.collection.document.assert_called_once_with("1")
        stored = self.collection.document.return_value.set.call_args.args[0]
        snapshot = Mock()
        snapshot.to_dict.return_value = {**stored, "private_field": "excluded"}
        self.query.stream.return_value = iter([snapshot])

        response = self.http.get("/api/meetings")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()[0]["title"], stored["title"])
        self.assertNotIn("private_field", response.json()[0])
        self.collection.order_by.assert_called_once_with("starts_at")
        self.collection.order_by.return_value.limit.assert_called_once_with(20)
        self.query.stream.assert_called_once_with(timeout=5)

    def test_database_failure_and_public_write_rejection(self):
        self.query.stream.side_effect = ServiceUnavailable("sensitive diagnostic")
        response = self.http.get("/api/meetings")
        self.assertEqual(response.status_code, 503)
        self.assertNotIn("sensitive diagnostic", response.text)
        self.assertEqual(self.http.post("/api/meetings").status_code, 405)
        self.assertEqual(self.http.put("/api/meetings/1/agenda").status_code, 404)
        self.assertEqual(self.http.get("/healthz").status_code, 200)


@unittest.skipUnless(os.environ.get("FIRESTORE_EMULATOR_HOST"), "requires Firestore emulator")
class FirestoreIntegrationTest(unittest.TestCase):
    def test_seed_is_idempotent_and_read(self):
        client = get_firestore()
        seed(client)
        seed(client)
        with TestClient(app) as http:
            response = http.get("/api/meetings")
            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.json()[0]["id"], 1)
        self.assertEqual([meeting.id for meeting in list_meetings(client)], [1])
