AWS_REGION ?= eu-central-1
ECR_REGISTRY ?= your-aws-account-id.dkr.ecr.$(AWS_REGION).amazonaws.com
S3_BUCKET ?= spry-frontend-bucket
CLOUDFRONT_DIST_ID ?= YOUR_DISTRIBUTION_ID

.PHONY: build-local up-local deploy-frontend deploy-backend report-now

# Local Development
up-local:
	docker compose up --build

# Deployment commands
deploy-frontend:
	cd frontend && npm ci && npm run build
	aws s3 sync frontend/dist/ s3://$(S3_BUCKET)/ --delete
	aws cloudfront create-invalidation --distribution-id $(CLOUDFRONT_DIST_ID) --paths "/*"

deploy-backend:
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(ECR_REGISTRY)
	docker build -t $(ECR_REGISTRY)/spry-backend:latest ./backend
	docker push $(ECR_REGISTRY)/spry-backend:latest
	aws ecs update-service --cluster spry-cluster --service spry-backend-service --force-new-deployment

report-now:
	@test -n "$(WEEK)" || (echo "Usage: make report-now WEEK=2026-W39" && exit 1)
	@QUEUE_URL=$$(aws cloudformation describe-stacks \
		--stack-name spry-reports \
		--region eu-north-1 \
		--query "Stacks[0].Outputs[?OutputKey=='ReportRequestsQueueUrl'].OutputValue" \
		--output text); \
	aws sqs send-message \
		--region eu-north-1 \
		--queue-url "$$QUEUE_URL" \
		--message-body '{"week":"$(WEEK)","source":"sqs"}'
