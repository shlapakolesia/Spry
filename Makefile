AWS_REGION ?= eu-north-1
export TEXT
AWS_ACCOUNT_ID ?= 664874246122
ECR_REGISTRY ?= $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
S3_BUCKET ?= spry-frontend-664874246122
CLOUDFRONT_DIST_ID ?= E1XBOI4V3UL61W

.PHONY: build-local up-local deploy-frontend deploy-backend infra-plan report-now llm-hello parse

# Local Development
up-local:
	docker compose up --build

# Deployment commands
deploy-frontend:
	cd frontend && npm ci && npm run build
	cp 'frontend/public /privacy.html' frontend/dist/privacy.html
	aws s3 sync frontend/dist/ s3://$(S3_BUCKET)/ --delete
	aws cloudfront create-invalidation --distribution-id $(CLOUDFRONT_DIST_ID) --paths "/*"

deploy-backend:
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(ECR_REGISTRY)
	docker build --platform linux/amd64 -t $(ECR_REGISTRY)/spry-backend:latest ./backend
	docker push $(ECR_REGISTRY)/spry-backend:latest
	aws ecs update-service --cluster spry-cluster --service spry-backend-service --force-new-deployment

# Plans run in the HCP Terraform workspace configured for remote execution.
infra-plan:
	terraform -chdir=infra plan

report-now:
	@test -n "$(WEEK)" || (echo "Usage: make report-now WEEK=2026-W39" && exit 1)
	@QUEUE_URL=$$(terraform -chdir=infra output -raw report_requests_queue_url); \
	aws sqs send-message \
		--region eu-north-1 \
		--queue-url "$$QUEUE_URL" \
		--message-body '{"week":"$(WEEK)","source":"sqs"}'

# Local Bedrock Mantle calls use the caller's AWS credential chain and the configured region.
llm-hello:
	cd backend && uv run python -c 'from app.ai.agenda import hello; hello()'

parse:
	@test -n "$$TEXT" || (echo "Usage: make parse TEXT='paste agenda text here'" && exit 1)
	cd backend && uv run python -c 'import json, os, time; from datetime import date; from app.ai.agenda import PROMPT_VERSION, cost_usd, parse_agenda; from app.config import PARSER_MODEL; started=time.monotonic(); agenda, usage=parse_agenda(os.environ["TEXT"], date.today(), "Europe/Kyiv"); print(json.dumps({"agenda": agenda.model_dump(mode="json"), "model": PARSER_MODEL, "prompt_version": PROMPT_VERSION, "usage": usage, "cost_usd": cost_usd(PARSER_MODEL, usage), "latency_ms": round((time.monotonic()-started)*1000)}, ensure_ascii=False, indent=2))'
