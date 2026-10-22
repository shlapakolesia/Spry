import os

DATABASE_URL: str = os.environ.get(
    "DATABASE_URL", "postgresql+psycopg://spry:spry@localhost:5432/spry"
)
PARSER_MODEL: str = os.environ.get("PARSER_MODEL", "anthropic.claude-opus-5-5")
BEDROCK_REGION: str = os.environ.get("BEDROCK_REGION", "us-east-1")
COGNITO_REGION: str = os.environ.get("COGNITO_REGION", "eu-north-1")
COGNITO_USER_POOL_ID: str = os.environ.get(
    "COGNITO_USER_POOL_ID", "eu-north-1_m4dJRmho3"
)
COGNITO_CLIENT_ID: str = os.environ.get(
    "COGNITO_CLIENT_ID", "1uucla7u51q5an1th1j48hjtbi"
)
PARSER_CORS_ORIGINS: str = os.environ.get(
    "PARSER_CORS_ORIGINS", "http://localhost:5173"
)
