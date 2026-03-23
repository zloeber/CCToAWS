#!/usr/bin/env zsh
set -euo pipefail

# Example: sync a local folder to the ABAC-scoped prefix and print next steps for Register.
# Usage: AWS_PROFILE=... ./publish-static.sh <bucket> <user_tag> <app_id> <local_dir>

if [[ $# -lt 4 ]]; then
  print "Usage: $0 <bucket> <user_tag> <app_id> <local_dir>" >&2
  exit 1
fi

bucket=$1
user_tag=$2
app_id=$3
local_dir=$4
prefix="${user_tag}/${app_id}/"

aws s3 sync "${local_dir}" "s3://${bucket}/${prefix}" --delete

print "Synced to s3://${bucket}/${prefix}"
print "Next: POST ${http_api_endpoint:-<set http_api_endpoint>}/v1/register with deployment_type=static and static_url=..."
