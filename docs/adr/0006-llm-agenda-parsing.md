# ADR 0006: LLM agenda parsing

- Status: Accepted; deployed model selected after successful Mantle inference
- Date: 2026-10-22

## Context

People receive agendas in emails, chats and notes rather than in Spry's structured form. The parser must accept external text, keep its cost bounded, and work without adding NAT to the database VPC. A suggestion can be wrong, so a person must review it before any write.

## Decision

Use Mistral Large 3 (`mistral.mistral-large-3-675b-instruct`) through the Bedrock Mantle Chat Completions API. The parser runs as a separate Lambda outside the VPC: it has no database requirement, reaches Bedrock directly, and adds no VPC endpoint or NAT cost. The Lambda uses the AWS credential provider chain and SigV4, with the Bedrock region set to `us-west-2`. It passes `ParsedAgenda.model_json_schema()` as the `record_agenda` function parameters, validates returned arguments with Pydantic, retries one invalid result, and returns a suggestion. The browser calls the normal API to save the user's reviewed agenda and keeps the original suggestion, model and prompt version beside it. The model has no write path.

## Model selection status and instructor exception

The original lab proposed Claude Opus 5.5, but Happy Path account-level access
restrictions prevented invocation. The instructor approved choosing another
model already available to the account. Mistral Large 3 was verified with a
real Mantle inference call in `us-west-2` (HTTP 200), followed by a successful
local `record_agenda` parse. The response reports the model label
`mistral.mistral-large-3-instruct`; requests use the documented model ID
`mistral.mistral-large-3-675b-instruct`. The `bedrock-runtime` daily token quota remains
exhausted; Mantle is a separate endpoint and the successful call used it.

## Alternatives considered

- Claude Opus 5.5: account-level model access prevented invocation (HTTP 403 / unavailable agreement).
- Claude Sonnet 5 and Claude Haiku 4.5: the owner observed HTTP 403 for these models.
- Amazon Nova Lite, Nova Pro, and Nova 2 Lite: real `bedrock-runtime` requests hit the shared daily-token throttle.
- Mistral Large 3 through `bedrock-runtime`: the same shared daily-token throttle applied. Mantle Chat Completions in `us-west-2` returned HTTP 200 and supports the required client-side tool call.
- Call Bedrock from the API inside the VPC: this would require outbound network access through NAT or a Bedrock interface endpoint and couples model latency to the database API.
- Call the Claude API directly: this adds a separate API credential to manage and bill outside the AWS account, while Bedrock fits the existing AWS IAM and billing model.
- Parse with regular expressions: this is cheap and deterministic but brittle across languages, email formats, and varied agenda text.

## Consequences

The cost function uses the AWS Bedrock Standard on-demand rate for Mistral Large 3 in US regions: $0.50 per million input tokens and $1.50 per million output tokens. The initial local Ukrainian smoke call (753 input, 192 output) estimated `$0.0006645`; the later five-case evaluation run for the same input (753 input, 187 output) estimated `$0.000657`. Each successful deployed parse emits one JSON CloudWatch line with user subject, model, prompt version, input/output tokens, latency and estimated cost. If Bedrock is unavailable or throttled, parsing returns an error and the user can type the agenda by hand; meeting creation and the rest of Spry continue to work.

The parser is deployed in `spry-ai-live` in `eu-north-1`. The first `spry-ai`
stack attempt rolled back because Lambda rejected a BuildKit image index with
provenance metadata; a single OCI image manifest fixed it. The failed rollback
record was retained rather than deleting the stack. The `$5` monthly budget is
created separately through the AWS Budgets API because
`AWS::Budgets::Budget` is not registered in CloudFormation's `eu-north-1`
resource type registry.

The parser has a public function URL, so every request verifies a Cognito ID token and rejects text over 10,000 characters before invoking the model. A monthly $5 AWS Budget sends actual and forecast alerts to the configured email.

## Previous AWS model-access blocker

The original lab proposed Claude Opus 5.5. Account-level restrictions prevented its invocation, and the instructor explicitly approved another model already available to the account. The exact Mantle model call in `eu-north-1` connected but timed out waiting for inference; the one requested fallback in `us-west-2` returned HTTP 200. The successful response reported 6 prompt and 5 completion tokens. A subsequent local parse also succeeded. No new commercial terms, quota increases, or organization-policy changes were made.
