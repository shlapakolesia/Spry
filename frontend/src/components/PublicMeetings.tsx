import { useEffect, useState } from "react";

import { listPublicMeetings } from "@/api/meetings";
import { MeetingCard } from "@/components/MeetingCard";
import type { MeetingSummary } from "@/types/meeting";

export function PublicMeetings() {
  const [meetings, setMeetings] = useState<MeetingSummary[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    void listPublicMeetings()
      .then((records) => {
        if (active) setMeetings(records);
      })
      .catch((failure: unknown) => {
        if (active) setError(failure instanceof Error ? failure.message : "Could not load meetings");
      });
    return () => {
      active = false;
    };
  }, []);

  return (
    <div className="min-h-screen bg-neutral-50">
      <main className="mx-auto max-w-2xl px-6 py-14">
        <h1 className="mb-2 text-3xl font-semibold tracking-tight">Meetings</h1>
        <p className="mb-8 text-sm text-muted-foreground">Spry lab · Public sample meetings</p>
        {error && (
          <p role="alert" className="text-sm text-destructive">
            {error}
          </p>
        )}
        {!meetings && !error && <p role="status">Loading…</p>}
        {meetings?.length === 0 && <p>No sample meetings yet.</p>}
        {meetings && meetings.length > 0 && (
          <ul className="grid gap-3">
            {meetings.map((meeting) => (
              <li key={meeting.id}>
                <MeetingCard meeting={meeting} readOnly />
              </li>
            ))}
          </ul>
        )}
      </main>
    </div>
  );
}
