# CloudWatch parse evidence

## Lambda parse log: pending authenticated call

The parser Lambda is deployed in `eu-north-1` as `spry-agenda-parser`. Its
Function URL correctly returned 401 for an unauthenticated POST, and its CORS
preflight returned the configured CloudFront origin, POST method, and
authorization/content-type headers. No successful authenticated invocation has
yet produced a Lambda `agenda_parsed` success record. The successful model
parses listed below were local calls, not Lambda logs.

## Real local inference evidence

- Model requested: `mistral.mistral-large-3-675b-instruct`
- Bedrock response model label: `mistral.mistral-large-3-instruct`
- Endpoint/API: Bedrock Mantle Chat Completions
- Region: `us-west-2`
- Authentication: SigV4 with AWS credential provider chain
- Minimal hello: HTTP 200, 6 prompt / 5 completion tokens
- `make llm-hello`: succeeded, 13 input / 51 output tokens
- Five evaluation parses: 3,543 input / 505 output tokens total
- Total five-call estimate: `$0.002529`; mean `$0.0005058`
- Individual tokens, costs, JSON and latency: [agenda evaluation](agenda-evaluation.md)

The five local cases completed on 2026-10-29. An authenticated browser session
is still needed to verify the deployed Parse → edit → Save flow and capture a
real CloudWatch parse line containing `event`, `user`, `model`,
`prompt_version`, `input_tokens`, `output_tokens`, `latency_ms`, and `cost_usd`.
