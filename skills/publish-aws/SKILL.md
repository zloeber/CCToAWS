---
name: publish-aws
description: Publish static sites to S3 and container images to ECR, then register deployment metadata in the shared HTTP API using AWS CLI with IAM Identity Center (Entra) credentials.
---

# Publish to AWS (CCToAWS)

Use this skill when the user wants to **deploy** a static website or **container image** into the shared platform and **register** it so internal routing/proxies can discover URLs.

## Prerequisites

- AWS CLI v2, Docker (for containers), `jq` optional but helpful.
- IAM Identity Center (SSO) profile configured: `aws configure sso` or equivalent.
- Terraform has already been applied once; you have:
  - `http_api_endpoint` (API Gateway HTTP API URL),
  - `static_bucket_id`,
  - `ecr_repository_url`,
  - `abac_user_tag_key` (session tag key, e.g. `user_id`),
  - IAM policies attached to the user’s permission set for S3 prefix, ECR, and `execute-api:Invoke`.

Store settings in a project file (example: `cct-config.json`):

```json
{
  "aws_profile": "my-sso-profile",
  "aws_region": "us-east-1",
  "http_api_endpoint": "https://xxxx.execute-api.us-east-1.amazonaws.com",
  "static_bucket": "cct-example-static-001",
  "ecr_repository_url": "123456789012.dkr.ecr.us-east-1.amazonaws.com/cct-user-apps",
  "abac_user_tag_key": "user_id"
}
```

The value for the ABAC prefix usually comes from the **same** session tag (for example corporate `user_id`). Confirm with your IAM admin if unsure.

## Workflow (static)

1. `aws sso login --profile <profile>`
2. Sync files to **your** prefix only: `s3://$BUCKET/$USER_TAG/$APP_ID/` (see `scripts/publish-static.sh`).
3. Call **`POST /v1/register`** with SigV4 credentials:

   - `deployment_type`: `static`
   - `app_id`: lowercase identifier (`a-z0-9-`, 2–63 chars)
   - `revision`: git SHA or timestamp
   - `static_url`: canonical HTTPS base for the site once the shared edge exists — **`https://<shared_host>/<user_tag>/<app_id>/`** (same path as the S3 prefix; trailing slash recommended)
   - `user_id` (optional but recommended): **ABAC tag value** (for example `user_id`) — must match the **Cognito `email` or `preferred_username`** if you use the web dashboard; otherwise dashboard queries cannot find apps.

## Workflow (container)

1. `aws ecr get-login-password` → `docker login` to the shared registry.
2. Tag and push: `$ECR_REPO_URL:$USER_TAG-$APP_ID-$REV` (or your org’s convention).
3. Run the workload: if your stack uses **`enable_alb_ecs`**, deploy to the shared **ECS cluster** behind the **ALB** (see Terraform output **`container_publish_https_url`** / **`container_publish_ecs_cluster_name`**) and IAM policy **`iam_policy_container_publish_arn`**; otherwise create/update **App Runner** or another runtime via CLI.
4. **`POST /v1/register`** with `deployment_type=container`, `image_uri`, and `runtime_url` (service URL).

## Register API (authoritative)

- **Endpoint:** `{http_api_endpoint}/v1/register` (stage is `$default`; no extra path segment).
- **Auth:** IAM SigV4 (same SSO role/user as deployments).
- **List:** `GET /v1/apps` — returns apps for the **current** caller only.
- **Get one:** `GET /v1/apps/{appId}`.

Minimal JSON body for static:

```json
{
  "app_id": "my-site",
  "deployment_type": "static",
  "revision": "abc123",
  "user_id": "alice",
  "static_url": "https://apps.example.internal/alice/my-site/"
}
```

Minimal JSON body for containers:

```json
{
  "app_id": "api-svc",
  "deployment_type": "container",
  "revision": "2026-03-23T12:00:00Z",
  "user_id": "alice",
  "image_uri": "123456789012.dkr.ecr.us-east-1.amazonaws.com/cct-user-apps:user-001-api-svc-001",
  "runtime_url": "https://xyz.us-east-1.awsapprunner.com/"
}
```

Use `aws` to sign requests, for example with `awscurl` or a short Python script using `botocore`/`requests` if `curl` alone is insufficient.

## EventBridge

ECR and S3 changes emit events to the **reconcile** Lambda (logging in v1). The **Register** call remains the **source of truth** for routing metadata.

## Escalation

- **CloudFront / WAF / ALB** in front of static origins or services are **platform extensions** — plan separately; keep registry URLs accurate when those endpoints change. Static delivery assumes **one shared hostname** and path **`/<user_tag>/<app_id>/`** aligned with the bucket prefix.
