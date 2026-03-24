# IAM Identity Center permission set (management account)

This configuration is **not** applied with the main workload stack. Run it from the **AWS Organizations management account** (or a **delegated administrator** for IAM Identity Center) using credentials that can call `sso-admin` APIs.

It creates a **permission set** whose **inline IAM policy** matches the three publisher policies in the workload account (S3 ABAC prefix, shared ECR with principal tag, `execute-api:Invoke` on the registry HTTP API).

## Prerequisites

1. **Workload account** — Apply `../` (parent `terraform/`) and capture outputs:

   ```bash
   cd ../
   terraform output -json > ../sso-management/workload-outputs.json
   ```

   Or copy manually: `static_bucket_arn`, `ecr_repository_arn`, `http_api_id`, `workload_aws_account_id`, `workload_aws_region`, `abac_user_tag_key`.

2. **Session tags** — The IdP ↔ IAM Identity Center attribute mapping must still pass a **session tag** whose key matches `abac_user_tag_key` (for example `user_id`). This Terraform does **not** configure Entra / Okta mappings.

3. **Optional policies** — If you add more IAM policies in the workload (for example ECS publish), attach them separately to this permission set in the console or extend `main.tf`.

## Deploy

```bash
cd terraform/sso-management
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with workload outputs.

terraform init
terraform plan
terraform apply
```

## Account assignment

- By default **`create_account_assignment`** is **false**. Assign the permission set to users/groups in the **workload** account via the IAM Identity Center console, or set `create_account_assignment = true` and provide **`assignment_principal_id`** (Identity Store user or group **ID**, not email).

## Why a separate root stack?

- IAM Identity Center resources (`aws_ssoadmin_*`) live in the **management** account API plane, while S3/ECR/API Gateway live in the **workload** account.
- Keeps **least privilege** for who can change organization-wide permission sets vs workload infrastructure.
