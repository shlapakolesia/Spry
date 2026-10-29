# CloudWatch and deployed save evidence

## Deployed parser log

On 2026-10-29 at `15:52:34.779Z`, the deployed `spry-agenda-parser` Lambda in
`eu-north-1` logged a successful parse. The user identifier is redacted here;
the remaining fields are from the real structured CloudWatch event:

```json
{
  "event": "agenda_parsed",
  "user": "<redacted>",
  "model": "mistral.mistral-large-3-675b-instruct",
  "prompt_version": "agenda-v1",
  "input_tokens": 769,
  "output_tokens": 205,
  "latency_ms": 1805,
  "cost_usd": 0.000692
}
```

The Lambda invocation completed successfully. Its CloudWatch REPORT duration
was `2001.69 ms`; parser latency above measures the inference parse section.
The cost uses the configured Mistral Large 3 token rates.

## Deployed persistence verification

The user completed Paste → Parse → changed the agenda title → Save agenda →
refresh in the deployed Spry UI. A read of the deployed meetings API then
confirmed meeting `4` contains the edited final agenda title
`зустріч по прайсингу`. The same saved row retains the original AI suggestion
title `синк по прайсингу`, model
`mistral.mistral-large-3-675b-instruct`, and prompt version `agenda-v1`.
The API response also contained the final agenda fields and the original
suggestion fields, confirming both persisted independently.

## Local inference and evaluation

- Model requested: `mistral.mistral-large-3-675b-instruct`
- Bedrock response model label: `mistral.mistral-large-3-instruct`
- Endpoint/API: Bedrock Mantle Chat Completions
- Region: `us-west-2`
- Authentication: SigV4 with AWS credential provider chain
- Minimal hello: HTTP 200, 6 prompt / 5 completion tokens
- `make llm-hello`: succeeded, 13 input / 51 output tokens
- Five evaluation parses: 3,543 input / 505 output tokens total
- Total five-call estimate: `$0.002529`; mean `$0.0005058`
- Individual JSON, correctness notes, tokens, cost, and latency: [agenda evaluation](agenda-evaluation.md)
