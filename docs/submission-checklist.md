# Part 4 submission checklist

| Submission item | Status | Evidence |
|---|---|---|
| Git commit containing parser, `infra/ai.yml`, Paste an agenda UI, and ADR | Pending GitHub authentication and final push | Parser Lambda and frontend are deployed; repository variable still needs authentication |
| Screen recording, GIF or MP4, at most 45 seconds | HUMAN ACTION NEEDED | [Video recording checklist](video-recording-checklist.md); authenticated deployed Parse → edit → Save still needs verification |
| Five-input Step 5 evaluation table | DONE LOCALLY; deployed UI retest pending | [Agenda evaluation](agenda-evaluation.md); all five cases have real local output and measurements |
| CloudWatch parse log with tokens, latency, and cost | Pending authenticated parse | [CloudWatch evidence](cloudwatch-evidence.md); no successful Lambda parse log yet |
| Four written Step 5 answers in Ukrainian | DONE | [Step 5 answers (Ukrainian)](step5-answers-uk.md) |

The implementation, migration, infrastructure template, architecture diagram,
and ADR are in the repository. Mistral Large 3 Mantle is deployed through
`spry-ai-live`, the additive migration has run, the `$5` monthly budget exists,
and CloudFront contains the parser URL. Deployed authenticated parse/save,
CloudWatch evidence, the repository Actions variable, and final GitHub push
remain. GitHub CLI authentication is currently awaiting a browser device login.
