import { useEffect, useRef, useState } from "react";

import { parseAgenda, saveAgenda } from "@/api/meetings";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import type { AiSuggestion, Meeting, ParsedAgenda } from "@/types/meeting";

const blankAgenda = (): ParsedAgenda => ({
  title: null,
  starts_at: null,
  duration_minutes: null,
  items: [],
  action_items: [],
  language: "en",
});

export function AgendaEditor({ meeting, token }: { meeting: Meeting; token?: string }) {
  const [source, setSource] = useState("");
  const [agenda, setAgenda] = useState<ParsedAgenda>(meeting.agenda ?? blankAgenda());
  const [suggestion, setSuggestion] = useState<AiSuggestion | null>(meeting.ai_suggestion);
  const [suggested, setSuggested] = useState(Boolean(meeting.ai_suggestion));
  const [touched, setTouched] = useState<Set<string>>(new Set());
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const controller = useRef<AbortController | null>(null);

  useEffect(() => () => controller.current?.abort(), []);
  const change = <K extends keyof ParsedAgenda>(field: K, value: ParsedAgenda[K]) => {
    setAgenda((current) => ({ ...current, [field]: value }));
    setTouched((current) => new Set(current).add(String(field)));
  };
  const hasSuggestedValue = (value: unknown): boolean => {
    if (typeof value === "string") return value.trim().length > 0;
    if (Array.isArray(value)) return value.some(hasSuggestedValue);
    if (value !== null && typeof value === "object") {
      return Object.values(value).some(hasSuggestedValue);
    }
    return value !== null && value !== undefined;
  };
  const badge = (key: keyof ParsedAgenda, value: unknown) => {
    const originalValue = suggestion?.agenda[key];
    const unchanged = JSON.stringify(value) === JSON.stringify(originalValue);
    return suggested && hasSuggestedValue(originalValue) && unchanged && !touched.has(key) ? (
      <span className="ml-2 rounded bg-secondary px-2 py-0.5 text-xs text-muted-foreground">Suggested</span>
    ) : null;
  };

  async function parse() {
    if (!token) {
      setError("Sign in to parse an agenda. You can still enter it by hand.");
      return;
    }
    controller.current?.abort();
    controller.current = new AbortController();
    setBusy(true);
    setError(null);
    setNotice(null);
    try {
      const now = new Date();
      const today = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`;
      const result = await parseAgenda(
        { text: source, today, tz: Intl.DateTimeFormat().resolvedOptions().timeZone },
        token,
        controller.current.signal,
      );
      const hasAgendaContent =
        hasSuggestedValue(result.agenda.title) ||
        result.agenda.items.some((item) => hasSuggestedValue(item.topic)) ||
        result.agenda.action_items.some((item) => hasSuggestedValue(item.task));
      if (!hasAgendaContent) {
        setError("No agenda was found in the pasted text. You can enter it by hand.");
        return;
      }
      const next = { agenda: result.agenda, model: result.model, prompt_version: result.prompt_version };
      setAgenda(result.agenda);
      setSuggestion(next);
      setSuggested(true);
      setTouched(new Set());
      setNotice("Review the suggested agenda and correct anything that needs changing.");
    } catch (e) {
      if (!(e instanceof DOMException && e.name === "AbortError"))
        setError(e instanceof Error ? e.message : "Network error. You can enter the agenda by hand.");
    } finally {
      setBusy(false);
    }
  }

  async function save() {
    setError(null);
    setNotice(null);
    try {
      await saveAgenda(meeting.id, agenda, suggestion, token);
      setNotice("Agenda saved.");
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not save the agenda.");
    }
  }

  return (
    <section className="grid gap-3" aria-label="Meeting agenda">
      <h3 className="font-medium">Agenda</h3>
      <label className="grid gap-2 text-sm">
        Paste an agenda
        <textarea
          className="min-h-24 rounded-md border bg-transparent p-3 text-sm"
          value={source}
          onChange={(event) => setSource(event.target.value)}
          placeholder="Paste an email, chat message, or meeting notes…"
        />
      </label>
      {source.length > 10000 && (
        <p role="alert" className="text-sm text-destructive">
          Text is too long. Use 10,000 characters or fewer.
        </p>
      )}
      <div className="flex flex-wrap gap-2">
        <Button
          type="button"
          variant="outline"
          disabled={busy || source.trim().length === 0 || source.length > 10000}
          onClick={() => void parse()}
        >
          {busy ? "Parsing…" : "Parse"}
        </Button>
        {busy && (
          <Button type="button" variant="outline" onClick={() => controller.current?.abort()}>
            Cancel
          </Button>
        )}
      </div>
      {busy && (
        <p role="status" className="text-sm text-muted-foreground">
          Parsing your agenda. This may take a few seconds…
        </p>
      )}
      {error && (
        <p role="alert" className="text-sm text-destructive">
          {error}
        </p>
      )}
      {notice && (
        <p role="status" className="text-sm text-muted-foreground">
          {notice}
        </p>
      )}
      <div className="grid gap-3 rounded-lg border p-4">
        <label className="grid gap-1 text-sm">
          Title{badge("title", agenda.title)}
          <Input value={agenda.title ?? ""} onChange={(e) => change("title", e.target.value || null)} />
        </label>
        <label className="grid gap-1 text-sm">
          Starts at{badge("starts_at", agenda.starts_at)}
          <Input
            value={agenda.starts_at ?? ""}
            onChange={(e) => change("starts_at", e.target.value || null)}
            placeholder="ISO 8601 with offset"
          />
        </label>
        <label className="grid gap-1 text-sm">
          Duration in minutes{badge("duration_minutes", agenda.duration_minutes)}
          <Input
            type="number"
            min={1}
            max={600}
            value={agenda.duration_minutes ?? ""}
            onChange={(e) => change("duration_minutes", e.target.value ? Number(e.target.value) : null)}
          />
        </label>
        <label className="grid gap-1 text-sm">
          Language{badge("language", agenda.language)}
          <Input value={agenda.language} onChange={(e) => change("language", e.target.value)} />
        </label>
        <div className="grid gap-2">
          <p className="text-sm font-medium">Topics{badge("items", agenda.items)}</p>
          {agenda.items.map((item, index) => (
            <div className="grid gap-2 rounded-md bg-muted p-3 sm:grid-cols-3" key={`item-${index}`}>
              <Input
                aria-label={`Topic ${index + 1}`}
                value={item.topic}
                onChange={(e) => {
                  const items = [...agenda.items];
                  items[index] = { ...item, topic: e.target.value };
                  change("items", items);
                }}
              />
              <Input
                aria-label={`Owner ${index + 1}`}
                placeholder="Owner"
                value={item.owner ?? ""}
                onChange={(e) => {
                  const items = [...agenda.items];
                  items[index] = { ...item, owner: e.target.value || null };
                  change("items", items);
                }}
              />
              <Input
                aria-label={`Minutes ${index + 1}`}
                type="number"
                min={1}
                max={480}
                placeholder="Minutes"
                value={item.minutes ?? ""}
                onChange={(e) => {
                  const items = [...agenda.items];
                  items[index] = { ...item, minutes: e.target.value ? Number(e.target.value) : null };
                  change("items", items);
                }}
              />
            </div>
          ))}
          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={() => change("items", [...agenda.items, { topic: "", owner: null, minutes: null }])}
          >
            Add topic
          </Button>
        </div>
        <div className="grid gap-2">
          <p className="text-sm font-medium">Action items{badge("action_items", agenda.action_items)}</p>
          {agenda.action_items.map((item, index) => (
            <div className="grid gap-2 rounded-md bg-muted p-3 sm:grid-cols-3" key={`action-${index}`}>
              <Input
                aria-label={`Action ${index + 1}`}
                value={item.task}
                onChange={(e) => {
                  const items = [...agenda.action_items];
                  items[index] = { ...item, task: e.target.value };
                  change("action_items", items);
                }}
              />
              <Input
                aria-label={`Action owner ${index + 1}`}
                placeholder="Owner"
                value={item.owner ?? ""}
                onChange={(e) => {
                  const items = [...agenda.action_items];
                  items[index] = { ...item, owner: e.target.value || null };
                  change("action_items", items);
                }}
              />
              <Input
                aria-label={`Due date ${index + 1}`}
                type="date"
                value={item.due ?? ""}
                onChange={(e) => {
                  const items = [...agenda.action_items];
                  items[index] = { ...item, due: e.target.value || null };
                  change("action_items", items);
                }}
              />
            </div>
          ))}
          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={() => change("action_items", [...agenda.action_items, { task: "", owner: null, due: null }])}
          >
            Add action item
          </Button>
        </div>
        <Button type="button" onClick={() => void save()}>
          Save agenda
        </Button>
      </div>
    </section>
  );
}
