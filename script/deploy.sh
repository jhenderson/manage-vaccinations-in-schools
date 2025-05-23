#!/usr/bin/env bash

set -e

terraform_cmd="terraform -chdir=terraform/app"

# Usage:
#  -f | --force : force deploying HEAD
while [[ $# -gt 0 ]]; do
  case $1 in
    -I|--image-digest)
      image_digest=$2
      shift; shift
      ;;
    -f|--force)
      force=true
      shift
      ;;
    -h|--help)
      echo "Usage: script/deploy.sh [options] <environment>"
      echo ""
      echo "Options:"
      echo "  -f | --force               : force deploying HEAD"
      echo "  -I | --image-digest DIGEST : Use the specified image digest instead of the latest one"
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

env="$1"

if [ -z "$env" ]; then
  echo "Environment not specified"
  echo "Usage: bin/deploy <environment>"
  exit 1
fi

if [ -z "$force" ]; then
  if [ "$(git branch --show-current)" != "main" ]; then
  echo "Not on main branch, please 'git checkout main'"
  exit 1
  fi

  if [ -n "$(git status --porcelain)" ]; then
  echo "Uncommitted changes, please 'git commit' or 'git stash'"
  exit 1
  fi

  if [ -n "$(git log origin/main..HEAD)" ]; then
  echo "Unpushed changes, please 'git push'"
  exit 1
  fi

  if [ -n "$(git diff --name-only origin/main)" ]; then
  echo "Unpulled changes, please 'git pull'"
  exit 1
  fi

  if [ -n "$(git fetch --dry-run)" ]; then
  echo "Unfetched changes, please 'git fetch'"
  exit 1
  fi
fi

if [[ -z "$image_digest" ]]; then
   sha=$(git rev-parse HEAD)
   image_digest=$(aws ecr batch-get-image --repository-name mavis/webapp --image-ids imageTag=$sha --query 'images[].imageId.imageDigest' --output text)
   if [[ -z "$image_digest" || "$image_digest" == "None" ]]
   then
     echo "Image not found in ECR with tag: $sha"
     exit 1
   fi
fi

$terraform_cmd init -backend-config=env/qa-backend.hcl -reconfigure
$terraform_cmd apply -var-file=env/qa.tfvars -var="image_digest=$image_digest"

s3_bucket=$($terraform_cmd output -raw s3_bucket)
s3_key=$($terraform_cmd output -raw s3_key)
application=$($terraform_cmd output -raw codedeploy_application_name)
application_group=$($terraform_cmd output -raw codedeploy_deployment_group_name)

deploy_id=$(aws deploy create-deployment \
          --application-name "$application" --deployment-group-name "$application_group" \
          --s3-location bucket="$s3_bucket",key="$s3_key",bundleType=yaml | jq -r .deploymentId)

echo "Deployment started, ID: $deploy_id"
