#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
# (but allow for the error trap)
set -eE

function report_err() {

    # Add some debug info

    # Debug OS-vars (skip secrets)
    env | grep OS_ | grep -v -e PASSWORD -e TOKEN -e OS_RC_FILE -e pass -e Pass -e PASS

    # Debug TF-vars (skip secrets)
    env | grep TF_VAR_ | grep -v -e PASSWORD -e TOKEN -e secret -e GOOGLE_CREDENTIALS -e aws_secret_access_key -e pass -e Pass -e PASS

}

# Trap errors
trap 'report_err' ERR

# read portal secrets from private repo
#if [ -z "$LOCAL_DEPLOYMENT" ]; then
#   source "$PORTAL_APP_REPO_FOLDER/phenomenal-cloudflare/cloudflare_token_phenomenal.cloud.sh"
#   export SLACK_ERR_REPORT_TOKEN=${cat \"$PORTAL_APP_REPO_FOLDER/phenomenal-cloudflare/slacktoken\"}
#fi

# Add terraform to path (TODO) remove this portal workaround eventually
export PATH=/usr/lib/terraform_0.10.7:$PATH

# Query Terraform state file
terraform show "$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/terraform.tfstate"
