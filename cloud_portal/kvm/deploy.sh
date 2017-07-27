#!/usr/bin/env bash
set -e

# provider specific
export KUBENOW_TERRAFORM_FOLDER="$PORTAL_APP_REPO_FOLDER/KubeNow/kvm"

"$PORTAL_APP_REPO_FOLDER/cloud_portal/shared/deploy.sh"
