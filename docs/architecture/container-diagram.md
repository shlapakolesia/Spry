# Spry containers (C4 level 2)

```mermaid
flowchart LR
  browser[Browser / React\nHuman reviews suggestion]

  subgraph outside[Outside VPC]
    parser[Agenda parser Lambda · eu-north-1\nNo database access]
    bedrock[Amazon Bedrock Mantle · us-west-2\nMistral Large 3 · Chat Completions]
  end

  subgraph vpc[Application VPC · eu-north-1]
    api[Spry API\nFastAPI]
    db[(Aurora PostgreSQL)]
  end

  browser -- "Parse: text + Cognito ID token" --> parser
  parser -- "record_agenda request" --> bedrock
  bedrock -- "structured suggestion" --> parser
  parser -- "suggestion JSON" --> browser
  browser -- "human-reviewed agenda + original suggestion" --> api
  api -- "validated save" --> db
```

The Bedrock response is only a suggestion. The parser cannot write to the database. The browser displays the suggestion for review, then saves through the normal API path.
