# ADR 0006: LLM agenda parsing

- Status: Accepted
- Date: 2026-10-22

## Context

People receive agendas in emails, chats and notes rather than in Spry's structured form. The parser must accept external text, keep its cost bounded, and work without adding NAT to the database VPC. A suggestion can be wrong, so a person must review it before any write.

## Decision

Use Claude Opus 5.5 on Amazon Bedrock (`anthropic.claude-opus-5-5`) through the Anthropic Messages API in us-east-1. The parser runs as a separate Lambda outside the VPC: it has no database requirement, reaches Bedrock directly, and adds no VPC endpoint or NAT cost. It validates the model's tool input against a Pydantic schema, retries one invalid result, and returns a suggestion. The browser calls the normal API to save the user's reviewed agenda and keeps the original suggestion, model and prompt version beside it. The model has no write path.

## Alternatives considered

- Call Bedrock from the API inside the VPC: this would require outbound network access through NAT or a Bedrock interface endpoint and couples model latency to the database API.
- Call the Claude API directly: this adds a separate API credential to manage and bill outside the AWS account, while Bedrock fits the existing AWS IAM and billing model.
- Parse with regular expressions: this is cheap and deterministic but brittle across languages, email formats, and varied agenda text.

## Consequences

Using the Part 1 Opus 5.5 list rates and its 10% regional-endpoint uplift, each parse is estimated at `1.10 × ($0.000004 × input tokens + $0.000020 × output tokens)`. This excludes account discounts and other billing adjustments. Each successful parse emits one JSON CloudWatch line with user subject, model, prompt version, input/output tokens, latency and estimated cost. If Bedrock is unavailable, parsing returns an error and the user can type the agenda by hand; meeting creation and the rest of Spry continue to work.

The parser has a public function URL, so every request verifies a Cognito ID token and rejects text over 10,000 characters before invoking the model. A monthly $5 AWS Budget sends actual and forecast alerts to the configured email.

## Current AWS access blocker

In account `664874246122`, Bedrock reports the required `anthropic.claude-opus-5-5` model as authorized, entitled, and regionally available in `us-east-1`, but its agreement availability is `NOT_AVAILABLE`. The live hello request returned HTTP 403 saying that the model is not available for this account. The Organizations SCP also denies listing model agreement offers. The parser model remains Opus 5.5 as required; no alternate model or policy change is being used. Deployment and live parse evidence are pending an approved agreement path.
