# CCToAWS Platform — Design (v1)

## Goals

- **Shared platform** in AWS (one account/region focus) with **IAM Identity Center** (Entra) users publishing **static content** (S3) and **container images** (ECR); runtime (e.g. App Runner) is created/updated via **CLI**, not Terraform per app.
- **Terraform** provisions **shared resources only** (buckets, repos, registry, API, Lambdas, EventBridge, IAM policies for ABAC).
- **Register API** is the **authoritative** record of what to route; **EventBridge** observes ECR/S3 activity for **reconciliation and audit**.
- **Admin portal** is **out of scope** for v1; **read APIs** list app metadata.

## Non-goals (v1)

- Per-user admin UI, multi-region active-active, full GitOps for user applications.
- CloudFront + WAF + ALB in Terraform (documented extension; operators may add in front of API and origins).

## Identity and ABAC

- Permission sets should propagate a **session tag** (configurable name, e.g. `user_id`) used in IAM conditions for S3 prefixes and ECR pushes.
- Register Lambda uses **SigV4 caller identity** from API Gateway (`requestContext.identity.userArn`) as the canonical **user key**.

## Control plane

- **DynamoDB** holds `USER#<principalArn>` / `APP#<appId>` items with deployment metadata and revision.
- **POST /v1/register** — idempotent upsert.
- **GET /v1/apps** — list apps for the caller.
- **Reconcile Lambda** — processes EventBridge payloads; v1 logs and may mark reconciliation state in a later iteration.

## Delivery URL model (part 2 — planned)

- **One shared hostname** for browser-facing HTTPS (for example CloudFront in front of the static bucket, optionally WAF). No per-app vanity hostnames in the baseline design.
- **Path convention (static):** mirror the S3 prefix so origins and IAM lines stay simple:

  `https://<shared_host>/<user_tag>/<app_id>/`

  Example: objects live at `s3://$BUCKET/alice/my-site/index.html`; the canonical site base is `https://<shared_host>/alice/my-site/` (trailing slash recommended for `static_url` in Register).
- **Register:** `static_url` should be that HTTPS base URL once the edge exists; until then publishers may use a placeholder or omit follow-up automation per environment.
- **Containers:** `runtime_url` remains the live service URL (App Runner, ECS behind ALB, etc.). A later iteration may **also** expose the same app under the shared hostname via path-based routing (for example `https://<shared_host>/svc/<user_tag>/<app_id>/`); that is an implementation choice when ALB/API routing is added—not required to match the static path shape.

## Skill

- Parameterize **account**, **region**, **API invoke URL**, **bucket**, **ECR repo**, **SSO profile**, and **ABAC tag key** (mirrors `terraform.tfvars`).
