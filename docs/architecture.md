# CCToAWS architecture

This document describes the shared publishing platform: **registry API**, **static sites** (S3), **containers** (ECR), optional **CloudFront**, optional **VPC + ALB + ECS Fargate** for container ingress, optional **web dashboard** (Cognito + JWT), and **EventBridge** reconciliation.

## Diagram

```mermaid
flowchart TB
  subgraph actors["Actors"]
    CLI["IAM Identity Center / CLI<br/>aws s3 sync, ECR push, SigV4 API"]
    BR["Browser"]
  end

  subgraph optional_edge["Optional: HTTPS edge"]
    CF["CloudFront + ACM<br/>shared hostname"]
  end

  subgraph optional_compute["Optional: Container ingress"]
    VPC["VPC + NAT"]
    ALB["Application LB<br/>HTTPS"]
    ECS["ECS Fargate<br/>cluster + tasks"]
  end

  subgraph optional_id["Optional: Dashboard identity"]
    COG["Cognito user pool<br/>Hosted UI / OAuth PKCE"]
  end

  subgraph api["API Gateway HTTP API"]
    IAMR["IAM routes<br/>POST /v1/register<br/>GET /v1/apps…"]
    JWTR["JWT routes<br/>GET/DELETE /v1/dashboard/apps…"]
  end

  L["registry-api Lambda"]

  subgraph data["Shared data plane"]
    DDB[("DynamoDB<br/>registry table + UserIdIndex GSI")]
    S3[("S3<br/>user sites + _platform/dashboard")]
    ECR[("ECR<br/>shared repository")]
  end

  subgraph events["Reconciliation"]
    EB["EventBridge<br/>ECR push, S3 object created"]
    RL["reconcile Lambda<br/>audit / logging"]
  end

  CLI -->|"SigV4"| IAMR
  CLI -->|"ABAC prefix write"| S3
  CLI -->|"push image"| ECR
  CLI -->|"ecs update-service<br/>task defs"| ECS

  VPC --> ALB
  ALB --> ECS
  ECS -->|"pull"| ECR

  BR -->|"OAuth sign-in"| COG
  BR -->|"Bearer access_token"| JWTR
  BR -->|"GET static assets"| CF

  CF -->|"OAC read"| S3

  IAMR --> L
  JWTR --> L
  L --> DDB

  ECR --> EB
  S3 --> EB
  EB --> RL
```

### Flow summary

| Path | Purpose |
|------|---------|
| **CLI → IAM routes** | Register deployment metadata (`POST /v1/register`); list apps by IAM principal (`GET /v1/apps`). |
| **CLI → S3 / ECR** | Publish assets and images (ABAC-scoped prefixes/tags). |
| **Browser → Cognito** | OAuth login for the dashboard (PKCE). |
| **Browser → JWT routes** | List/delete registry rows by **`user_id`** (must match `user_id` on register items). |
| **Browser → CloudFront → S3** | Serve static sites and the dashboard SPA from the same bucket (path-based). |
| **CLI → VPC / ALB / ECS** (optional) | Fargate tasks in private subnets; ALB terminates TLS; NAT for image pull. Use outputs for **`runtime_url`**. |
| **EventBridge** | ECR and S3 notifications to the reconcile Lambda (registry remains source of truth). |

## Regenerate the PNG

With Graphviz installed and Python dependencies:

```bash
pip install -r scripts/requirements-diagrams.txt
python3 scripts/generate_architecture_diagram.py --out docs/cct_to_aws_architecture
```

This overwrites `docs/cct_to_aws_architecture.png` (and related outputs from the `diagrams` library).
