# CCToAWS Platform Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a self-contained repository with Terraform for **shared AWS resources**, a **control plane** (HTTP API + Lambdas + DynamoDB + EventBridge), **ABAC-oriented IAM policy artifacts**, a **Claude Code skill**, and **CLI scripts** so operators publish static sites and container images using AWS SSO — without Terraform per application.

**Architecture:** One `terraform apply` provisions buckets, ECR, registry table, API, Lambdas, and event rules. Application lifecycle actions (sync, push, App Runner create/update) use **AWS CLI** and are documented in the skill. The **Register** API remains the **source of truth**; EventBridge events support **reconciliation and auditing**.

**Tech Stack:** Terraform (AWS provider), Python 3.12 Lambdas, API Gateway HTTP API (IAM auth), DynamoDB, EventBridge, S3, ECR, optional App Runner via CLI.

---

## File map

| Path | Responsibility |
|------|----------------|
| `terraform/` | Root module wiring shared resources |
| `terraform/modules/s3_static/` | Website bucket + EventBridge notifications |
| `terraform/modules/ecr_shared/` | Shared ECR repository + lifecycle |
| `terraform/modules/dynamodb_registry/` | App metadata table |
| `terraform/modules/control_plane/` | Lambdas, HTTP API, logging, EventBridge targets |
| `src/lambda/` | `register`, `reconcile` handlers |
| `scripts/` | Example publish flows using AWS CLI |
| `skills/publish-aws/SKILL.md` | Claude Code skill |
| `docs/superpowers/specs/2026-03-23-platform-design.md` | Design decisions |

---

### Task 1: Documentation and repo hygiene

**Files:**
- Create: `docs/superpowers/specs/2026-03-23-platform-design.md`
- Create: `.gitignore`

- [x] Write concise design spec (goals, boundaries, flows).
- [x] Ignore `.terraform/`, `*.tfstate*`, `*.zip`, `__pycache__`.

### Task 2: Terraform — data plane

**Files:**
- Create: `terraform/versions.tf`, `providers.tf`, `variables.tf`, `outputs.tf`, `main.tf`
- Create: `terraform/modules/s3_static/*`, `ecr_shared/*`, `dynamodb_registry/*`

- [x] S3 bucket: encryption, block public access, EventBridge notification enabled.
- [x] ECR repository with basic lifecycle policy.
- [x] DynamoDB table `pk` / `sk` with PAY_PER_REQUEST.

### Task 3: Terraform — control plane

**Files:**
- Create: `terraform/modules/control_plane/*`
- Create: `src/lambda/register.py`, `reconcile.py`

- [x] Package Lambdas with `archive_file` (stdlib + boto3).
- [x] HTTP API: `POST /v1/register`, `GET /v1/apps` with `AWS_IAM` auth.
- [x] EventBridge rules: ECR image push, S3 Object Created (optional filter).
- [x] IAM roles: Lambda execution, EventBridge → Lambda.

### Task 4: ABAC policy artifacts

**Files:**
- Create: `terraform/iam_policies.tf` (or inline in `main.tf`)

- [x] `aws_iam_policy` documents for S3 prefix + ECR push scoped by principal tag (var-driven tag key).
- [x] Outputs: policy ARNs, JSON for manual attachment to Identity Center permission sets if needed.

### Task 5: Skill and scripts

**Files:**
- Create: `skills/publish-aws/SKILL.md`
- Create: `scripts/publish-static.sh`, `scripts/publish-container.sh`
- Create: `README.md`, `terraform/terraform.tfvars.example`

- [x] Skill: prerequisites, SSO login, variables, register flow, links to Terraform outputs.
- [x] Scripts: zsh, `set -euo pipefail`, documented placeholders.

### Task 6: Verification

- [x] `terraform fmt -recursive`
- [x] `terraform init -backend=false && terraform validate`
- [x] `python3 -m py_compile` on Lambda sources

---

## Notes for operators

- **CloudFront / WAF / ALB** for internal hostnames are **not** created in v1 Terraform; the README explains how to add them without changing the skill’s core flows.
- **App Runner** and **ECS Fargate** are both achievable from the CLI; the registry stores opaque URLs — v1 examples favor **App Runner** with commands in the skill.
