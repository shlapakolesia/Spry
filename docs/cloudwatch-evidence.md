# CloudWatch parse evidence

## Status: BLOCKED — no successful parse exists

No CloudWatch `agenda_parsed` record is available because the required Bedrock
model call is blocked before inference. The local `make llm-hello` call returned
HTTP 403 for `anthropic.claude-opus-5-5` with the message that the model is not
available for this account. Bedrock reported `agreementAvailability:
NOT_AVAILABLE`; AWS Organizations explicitly denies the agreement-offer listing
API. No parse tokens, latency, or cost were returned, and no successful parse
log is claimed here.

When model access is enabled, capture one `agenda_parsed` JSON line from the
parser Lambda log group. It should include `model`, `prompt_version`,
`input_tokens`, `output_tokens`, `latency_ms`, and `cost_usd`. Do not use the
throttling/error log as a successful parse example.
