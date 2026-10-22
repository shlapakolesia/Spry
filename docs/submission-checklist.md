# Part 4 submission checklist

| Submission item | Status | Evidence |
|---|---|---|
| Git commit containing parser, `infra/ai.yml`, Paste an agenda UI, and ADR | DONE LOCALLY — `1edd44b`; push withheld | A push to `main` runs the frontend deploy workflow. The parser stack has no verified Function URL because it has not been created; publishing without that endpoint could leave Parse unusable. |
| Screen recording, GIF or MP4, at most 45 seconds | HUMAN ACTION NEEDED | [Video recording checklist](video-recording-checklist.md); live parser is currently blocked |
| Five-input Step 5 evaluation table | BLOCKED — AWS model access | [Agenda evaluation](agenda-evaluation.md); no model results fabricated |
| CloudWatch parse log with tokens, latency, and cost | BLOCKED — no successful parse | [CloudWatch evidence](cloudwatch-evidence.md) |
| Four written Step 5 answers in Ukrainian | DONE | [Step 5 answers (Ukrainian)](step5-answers-uk.md) |

The implementation, migration, infrastructure template, architecture diagram,
and ADR are in the repository. AWS deployment is blocked by the model agreement
restriction and the CloudFormation validation SCP denial. Publication remains
withheld until a valid parser Function URL can be configured safely.
