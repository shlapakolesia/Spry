# ADR 0007: Manage selected AWS infrastructure with Terraform

- **Status:** Accepted
- **Date:** 2026-10-30

## Decision

Migrate only authentication, weekly reports, and agenda parser resources from CloudFormation to Terraform. Terraform was selected over continuing with CloudFormation or introducing CDK because these resources can be described directly with the AWS provider, and Terraform supports importing the existing resources into remote state. OpenTofu was not selected because the repository and HCP workflow already use Terraform.

The `spry-dev` HCP Terraform workspace is connected to `shlapakolesia/Spry`, branch `main`, working directory `infra`, with Remote execution. AWS access uses HCP OIDC dynamic credentials scoped to this workspace. Terraform state and run records remain in HCP Terraform; no state files are committed.

Secrets are stored as sensitive HCP workspace variables. The imported Cognito Google client secret, report database URL, and report email are not committed. Terraform ignores changes to those existing secret-bearing values so import runs do not resend or expose them; update the AWS values through the existing secret rotation process and keep the HCP variables synchronized.

## Operations and recovery

If HCP Terraform is unavailable, existing AWS resources continue running. Plans and applies wait until the workspace is available again; state is not moved to a local backend. Review an HCP plan before applying and keep the AWS OIDC role limited to this workspace.

The resources from `spry-reports` and `spry-ai-live` were retained in AWS before their CloudFormation stack objects were removed. Cognito resources existed without an `spry-auth` CloudFormation stack. All 35 importable Terraform resources, including separately managed S3 configuration and IAM policies/attachments, were imported. No resources are recreated. The AWS monthly budgets and unrelated stacks remain outside this migration.
