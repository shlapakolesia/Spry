# Part 4 submission checklist

| Submission item | Status | Evidence |
|---|---|---|
| Git commit containing parser, `infra/ai.yml`, Paste an agenda UI, and ADR | DONE | `8277990ea7b153a5433a749182c5dde6bf35bb4b` on `main`; pushed to `origin` |
| Screen recording, GIF or MP4, at most 45 seconds | HUMAN ACTION NEEDED | [Video recording checklist](video-recording-checklist.md) |
| Five-input Step 5 evaluation table | DONE LOCALLY | [Agenda evaluation](agenda-evaluation.md); five real local outputs and measurements |
| Deployed Parse → edit → Save → refresh | DONE | User completed the flow; deployed API confirmed the edited title and original suggestion persisted |
| CloudWatch parse log with tokens, latency, and cost | DONE | [CloudWatch evidence](cloudwatch-evidence.md); real `agenda_parsed` Lambda log recorded |
| Four written Step 5 answers in Ukrainian | DONE | [Step 5 answers (Ukrainian)](step5-answers-uk.md) |

The implementation, migration, infrastructure template, architecture diagram,
and ADR are in the repository. Mistral Large 3 Mantle is deployed through
`spry-ai-live`, the additive migration has run, the `$5` monthly budget exists,
and CloudFront contains the parser URL. The repository Actions variable is set,
the changes are pushed, and the frontend and backend deployment workflows pass.
