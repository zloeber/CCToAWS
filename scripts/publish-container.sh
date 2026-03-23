#!/usr/bin/env zsh
set -euo pipefail

# Example: docker build, tag, push to shared ECR. Set AWS_REGION and ECR_REPOSITORY_URL.
# Usage: ./publish-container.sh <user_tag> <app_id> <image_tag_suffix> <dockerfile_context>

if [[ $# -lt 4 ]]; then
  print "Usage: $0 <user_tag> <app_id> <image_tag_suffix> <dockerfile_context>" >&2
  exit 1
fi

user_tag=$1
app_id=$2
suffix=$3
ctx=$4

: "${AWS_REGION:?Set AWS_REGION}"
: "${ECR_REPOSITORY_URL:?Set ECR_REPOSITORY_URL (e.g. 123.../repo)}"

full_tag="${user_tag}-${app_id}-${suffix}"
image="${ECR_REPOSITORY_URL}:${full_tag}"

registry="${ECR_REPOSITORY_URL%%/*}"
aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${registry}"

docker build -t "${image}" "${ctx}"
docker push "${image}"

print "Pushed ${image}"
print "Next: create/update App Runner or ECS, then POST /v1/register with deployment_type=container."
