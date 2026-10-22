import type { AiSuggestion, Meeting, MeetingCreate, ParsedAgenda } from "@/types/meeting";

interface ValidationError {
  msg: string;
}

interface ErrorBody {
  detail?: ValidationError[] | string;
}

async function errorMessage(response: Response): Promise<string> {
  try {
    const body = (await response.json()) as ErrorBody | null;
    const detail = body?.detail;
    if (Array.isArray(detail) && detail.length > 0) {
      return detail.map((d) => d.msg).join("; ");
    }
  } catch {
    // fall through to the generic message
  }
  return `Request failed (${response.status})`;
}

export async function listMeetings(token?: string): Promise<Meeting[]> {
  const response = await fetch("/api/meetings", { headers: token ? { Authorization: `Bearer ${token}` } : {} });
  if (!response.ok) throw new Error(await errorMessage(response));
  return (await response.json()) as Meeting[];
}

export async function createMeeting(input: MeetingCreate, token?: string): Promise<Meeting> {
  const response = await fetch("/api/meetings", {
    method: "POST",
    headers: { "Content-Type": "application/json", ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify(input),
  });
  if (!response.ok) throw new Error(await errorMessage(response));
  return (await response.json()) as Meeting;
}

export async function parseAgenda(
  input: { text: string; today: string; tz: string },
  token: string,
  signal: AbortSignal,
) {
  const url = import.meta.env.VITE_AGENDA_PARSER_URL as string | undefined;
  if (!url) throw new Error("Agenda parsing is not configured. You can enter the agenda by hand.");
  let response: Response;
  try {
    response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
      body: JSON.stringify(input),
      signal,
    });
  } catch (error) {
    if (signal.aborted) throw error;
    throw new Error("Network error. Check your connection, then try again or enter the agenda by hand.", {
      cause: error,
    });
  }
  if (!response.ok) {
    let message =
      response.status === 413
        ? "Text is too long. Use 10,000 characters or fewer."
        : response.status === 422
          ? "The parser could not find an agenda. You can enter it by hand."
          : response.status === 401
            ? "Your sign-in expired. Sign in again to parse an agenda."
            : response.status === 429
              ? "Too many requests. Please wait a moment and try again."
              : response.status === 503
                ? "The parser is busy. Please try again or enter the agenda by hand."
                : `Could not parse the agenda (${response.status}). You can enter it by hand.`;
    try {
      const body = (await response.json()) as { error?: string };
      if (body.error && response.status !== 413 && response.status !== 429) message = body.error;
    } catch {
      /* retain message */
    }
    throw new Error(message);
  }
  return (await response.json()) as { agenda: ParsedAgenda; model: string; prompt_version: string };
}

export async function saveAgenda(
  meetingId: number,
  agenda: ParsedAgenda,
  suggestion: AiSuggestion | null,
  token?: string,
): Promise<Meeting> {
  const response = await fetch(`/api/meetings/${meetingId}/agenda`, {
    method: "PUT",
    headers: { "Content-Type": "application/json", ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify({ agenda, ai_suggestion: suggestion }),
  });
  if (!response.ok) throw new Error(await errorMessage(response));
  return (await response.json()) as Meeting;
}
