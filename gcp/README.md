# Deploy Spry to Google Cloud

Firebase Hosting serves the Spry React build and forwards `/api/**` to Cloud Run in Iowa. A read-only FastAPI entry point queries the default Firestore Native database through a dedicated runtime identity. The lab uses one seeded public meeting and accepts no public writes. The PostgreSQL/Alembic app, AWS CI, Cognito, reports and agenda parser remain on the AWS deployment path.

## 1. Project, billing and credentials

Use the dedicated application project `spry-ucu-lab-2026-a83f`. Its default Firestore database and one synthetic meeting already exist, and billing is disabled. The separate `spry-ucu-sandbox-2026-74cf` project is for BigQuery. Leave the existing authentication project alone. Install Terraform ≥1.10, gcloud, Docker, Python 3.13, and Node 24. Run commands from the repository root.

The Blaze plan is required for Hosting rewrites to Run. Usage is expected to fit free quotas. Linking billing authorizes overages. Enable billing and apply only after approving that risk. Create a budget in Cloud Console → Billing → Budgets & alerts → Create budget. Scope it to the new project, set $5 monthly, and use actual thresholds of 50%, 90% and 100%. This budget sends alerts. Review other usage on the billing account before proceeding.

```bash
export SPRY_GCP_PROJECT="spry-ucu-lab-2026-a83f"
gcloud auth login
gcloud auth application-default login
```

For a separate reproduction, generate a unique ID with `export SPRY_GCP_PROJECT="spry-ucu-lab-$(openssl rand -hex 4)"` and run `gcloud projects create "$SPRY_GCP_PROJECT" --name="Spry UCU Cloud Lab"`. IDs are permanent and globally unique.

In Billing → My projects, link the dedicated project to the approved account and create the budget before provisioning services. In Firebase Console → Add project → select the existing GCP project → turn off Google Analytics unless needed. CLI alternative after setting up billing is `npx --yes firebase-tools@15 login` followed by `npx --yes firebase-tools@15 projects:addfirebase "$SPRY_GCP_PROJECT"`. If Firebase terms are presented, accept them in your own session. The Firebase plan shows Blaze when the billing account is linked. Confirm `gcloud billing projects describe "$SPRY_GCP_PROJECT"` and set the ADC quota project. If Service Usage is disabled, enable it in APIs & Services first.

```bash
gcloud auth application-default set-quota-project "$SPRY_GCP_PROJECT"
export TF_VAR_project_id="$SPRY_GCP_PROJECT"
```

## 2. Separate state and bootstrap

Local state defaults to `gcp/bootstrap/terraform.tfstate` and `gcp/terraform.tfstate`. Keep both private and backed up. For the assignment's HCP state, create two new CLI-driven HCP workspaces, `spry-gcp-bootstrap` and `spry-gcp-lab`, in your organization. In each workspace open Settings → General and choose **Local** execution. The CLI uses local ADC and HCP stores state and locks. The existing `spry-dev` workspace remains isolated.

Run `terraform login`. To configure HCP before the first init, use the following after setting the organization name. If those directories already have local state, back it up and follow HCP's state migration prompts before applying.

```bash
export SPRY_HCP_ORG="replace-with-your-hcp-organization"
cat > gcp/hcp.tf <<HCL
terraform {
  cloud {
    organization = "$SPRY_HCP_ORG"
    workspaces { name = "spry-gcp-lab" }
  }
}
HCL
sed 's/spry-gcp-lab/spry-gcp-bootstrap/' gcp/hcp.tf > gcp/bootstrap/hcp.tf
```

The bootstrap operator needs project-scoped authority for API enablement, IAM policy, service accounts, Firestore database creation, Artifact Registry and optional federation. Appropriate predefined roles include Service Usage Admin, Project IAM Admin, Service Account Admin, Cloud Datastore Owner, Artifact Registry Administrator and optional Workload Identity Pool Admin. Use the project creator or a designated administrator for this phase. The Terraform deployment identity has Cloud Run Admin for the dedicated project, Artifact Registry Reader scoped to the lab repository, and act-as on the single runtime service account. The runtime only has Firestore viewer. CI, if enabled, uses a separate repository-level writer.

```bash
terraform -chdir=gcp/bootstrap init
terraform -chdir=gcp/bootstrap validate
terraform -chdir=gcp/bootstrap state list
terraform -chdir=gcp/bootstrap plan
terraform -chdir=gcp/bootstrap apply
```

The current checkout's bootstrap state already tracks the Firestore API and database. Preserve that state when switching to HCP. In a fresh checkout without access to the original state, import the existing resources before the bootstrap plan or apply. Import only when neither resource is already in state.

```bash
terraform -chdir=gcp/bootstrap import google_project_service.firestore "$SPRY_GCP_PROJECT/firestore.googleapis.com"
terraform -chdir=gcp/bootstrap import google_firestore_database.lab "projects/$SPRY_GCP_PROJECT/databases/(default)"
```

If Terraform returns `serviceusage.services.list` denied while gcloud can see the project, renew ADC as the same project operator selected in gcloud. Terraform and gcloud use separate credentials.

Optional WIF setup goes **before** running bootstrap, or re-plan afterwards. Use repository metadata from `gh api repos/shlapakolesia/Spry --jq '[.id,.owner.id]'`. Copy `gcp/bootstrap/terraform.tfvars.example` to `gcp/bootstrap/terraform.tfvars`, set the new project and both numeric IDs, and review the plan. In GitHub Settings → Environments create `gcp-lab` and restrict deployment to `lab-gcp`. Set environment variables `GCP_PROJECT_ID`, `GCP_WIF_PROVIDER` and `GCP_PUBLISHER_SA` using the bootstrap outputs `github_provider` and `publisher_service_account`. Only when ready to publish, set repository variable `GCP_ENABLE_IMAGE_PUBLISH=true`. The next push to `lab-gcp` can publish and print the digest. Disable the variable after use to avoid unneeded images. Cloud Run deployment stays under Terraform. The WIF provider checks numeric repository and owner IDs and the branch. No key is issued.

## 3. Image, seed and API

For manual publishing, use an operator with Artifact Registry Writer on **this repository**. Run Docker locally to avoid Cloud Build meters. Review the pushed compressed image size and the billing account's registry allowance.

```bash
export SPRY_REGISTRY="$(terraform -chdir=gcp/bootstrap output -raw image_repository)"
export SPRY_TAG="$(git rev-parse --short HEAD)"
gcloud auth configure-docker us-central1-docker.pkg.dev
docker build --platform linux/amd64 --provenance=false -f backend/Dockerfile.gcp -t "$SPRY_REGISTRY:$SPRY_TAG" backend
docker push "$SPRY_REGISTRY:$SPRY_TAG"
export TF_VAR_image_digest="$(gcloud artifacts docker images describe "$SPRY_REGISTRY:$SPRY_TAG" --format='value(image_summary.digest)')"
```

Seed with a designated operator allowed to write Firestore documents in this project, for example Cloud Datastore User granted for seeding. Run this once. Repeat if necessary to restore the same synthetic record. Unset `FIRESTORE_EMULATOR_HOST` for cloud seeding. The AWS data stays on AWS.

```bash
python3.13 -m venv backend/.venv
backend/.venv/bin/pip install -r backend/requirements-gcp.txt
(cd backend && .venv/bin/python -m app.firestore_meetings --confirm-project "$SPRY_GCP_PROJECT")
```

The operator needs Service Account Token Creator on the single deployment identity. Grant this as bootstrap administrator to your own named operator, then set provider impersonation for the service plan and apply. Keep the variable unset for bootstrap.

```bash
SPRY_TF_SA="$(terraform -chdir=gcp/bootstrap output -raw terraform_service_account)"
SPRY_OPERATOR="$(gcloud config get-value account)"
gcloud iam service-accounts add-iam-policy-binding "$SPRY_TF_SA" \
  --project="$SPRY_GCP_PROJECT" --member="user:$SPRY_OPERATOR" \
  --role=roles/iam.serviceAccountTokenCreator
terraform -chdir=gcp init
GOOGLE_IMPERSONATE_SERVICE_ACCOUNT="$SPRY_TF_SA" terraform -chdir=gcp plan
GOOGLE_IMPERSONATE_SERVICE_ACCOUNT="$SPRY_TF_SA" terraform -chdir=gcp apply
SPRY_API="$(terraform -chdir=gcp output -raw api_url)"
curl -fsS "$SPRY_API/healthz"
curl -fsS "$SPRY_API/api/meetings"
```

Expect one record with title **Spry cloud architecture walkthrough**, ID 1 and six attendees. Record the API HTTPS URL from Terraform output. The browser uses a rewrite and needs no cross-origin configuration. Standard request logs and sanitized query failures go to Cloud Logging. The request timeout is 15 seconds with one configured instance maximum and zero minimum. Public invoker IAM checking is disabled intentionally for this isolated service that only shows synthetic data. The live deployment still depends on any organization policy permitting public Cloud Run access.

## 4. Publish and verify the frontend

```bash
(cd frontend && npm ci && VITE_SPRY_GCP_DEMO=true npm run build -- --outDir ../gcp/hosting-dist --emptyOutDir)
(cd gcp && npx --yes firebase-tools@15 deploy --only firestore:rules,hosting --project "$SPRY_GCP_PROJECT")
SPRY_SITE="https://$SPRY_GCP_PROJECT.web.app"
curl -fsS "$SPRY_SITE/" > /dev/null
curl -fsS "$SPRY_SITE/api/meetings"
printf 'Frontend %s\nAPI %s\n' "$SPRY_SITE" "$SPRY_API"
```

If the CLI prints a different Hosting URL, use that URL. In an incognito window, load the site and check the meeting card, the CSS/JS responses and the `/api/meetings` response using DevTools → Network. Verify the document in Firestore → Data → `lab_meetings` → `1`. Confirm no sign-in redirect and no write controls. Capture the site and network evidence if desired. The deployed rules deny Firebase client access. The backend server SDK uses IAM.

## 5. Local checks

```bash
terraform fmt -check -recursive gcp
terraform -chdir=gcp/bootstrap validate
terraform -chdir=gcp validate
backend/.venv/bin/pip install httpx
(cd backend && .venv/bin/python -m unittest discover -s tests -v)
(cd frontend && npm run lint && npm run build && VITE_SPRY_GCP_DEMO=true npm run build)
```

For a real local Firestore integration test, install gcloud components `beta` and `cloud-firestore-emulator` and Java 21. Start `gcloud beta emulators firestore start --host-port=127.0.0.1:8787 --project=spry-emulator` in a separate terminal. Run `(cd backend && FIRESTORE_EMULATOR_HOST=127.0.0.1:8787 SPRY_GCP_PROJECT=spry-emulator .venv/bin/python -m unittest discover -s tests -v)`. Stop the emulator when finished. This test covers the actual seed, adapter and query against local Firestore. It does not exercise cloud IAM or Firebase.

## 6. Cleanup after grading

Keep the live URL until evidence is saved and the grader no longer needs access. Leaving it reachable can accrue traffic and logs. No Cloud SQL is used, so there is no SQL instance to stop. If you separately used regular Cloud SQL, stop it in Cloud SQL → instance → Stop to stop CPU charges, or delete it when storage is no longer needed.

1. In GitHub remove or disable `GCP_ENABLE_IMAGE_PUBLISH`. Disable Firebase Hosting with `(cd gcp && npx --yes firebase-tools@15 hosting:disable --project "$SPRY_GCP_PROJECT")`.
2. Restore the exact project identifier and image digest from the deployment shell. Inspect `terraform -chdir=gcp state list` and `terraform -chdir=gcp/bootstrap state list`. Then run `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT="$SPRY_TF_SA" terraform -chdir=gcp destroy` before `terraform -chdir=gcp/bootstrap destroy`. Review each destroy plan. These commands remove the API, registry, Firestore and lab IAM identities. The Firebase project registration and manually enabled demo APIs are outside Terraform.
3. If Dataflow was opted into, inspect completed or active jobs, delete only lab staging/input/output buckets and BigQuery demo tables, and remove any demo service account. For the separate BigQuery sandbox, export evidence, then delete the sandbox project or keep it unbilled for grading.
4. Confirm `gcloud run services list --project="$SPRY_GCP_PROJECT" --region=us-central1`, `gcloud artifacts repositories list --project="$SPRY_GCP_PROJECT" --location=us-central1`, and `gcloud firestore databases list --project="$SPRY_GCP_PROJECT"` are empty. Check Cloud Console → Billing → Reports with the project filter the next day. Delete the dedicated application project via IAM & Admin → Settings → Shut down if it is no longer needed. Never run these cleanup steps against the AWS configuration or a shared project.
