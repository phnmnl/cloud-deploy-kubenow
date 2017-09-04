#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
# (but allow for the error trap)
set -eE

function report_err() {
  # post deployment log to slack channel (only if portal deployment)
  if [[ ! -n "$LOCAL_DEPLOYMENT" ]]; then
    curl -F file="@$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/output.log" \
         -F filename="output-$PORTAL_DEPLOYMENT_REFERENCE.log" \
         -F filetype="shell" \
	     -F channels="portal-deploy-error" \
	     -F token="$SLACK_ERR_REPORT_TOKEN" \
	     https://slack.com/api/files.upload
  fi
}

# Trap errors
trap 'report_err' ERR

# Destroy everything
cd "$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE"

ansible_inventory_file="$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/inventory"

# read portal secrets from private repo
if [ -z "$LOCAL_DEPLOYMENT" ]; then
   source "$PORTAL_APP_REPO_FOLDER/phenomenal-cloudflare/cloudflare_token_phenomenal.cloud.sh"
   export SLACK_ERR_REPORT_TOKEN=$(cat "$PORTAL_APP_REPO_FOLDER/phenomenal-cloudflare/slacktoken")
fi

# TODO read this from deploy.sh file
export TF_VAR_kubenow_image="kubenow-v031"
export TF_VAR_kubeadm_token="fake.token"
export TF_VAR_master_disk_size="20"
export TF_VAR_node_disk_size="20"
export TF_VAR_edge_disk_size="20"
export TF_VAR_glusternode_disk_size="20"
export TF_VAR_ssh_key="$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/vre.key.pub"

# Add terraform to path (TODO) remove this portal workaround eventually
export PATH=/usr/lib/terraform_0.9.11:$PATH

terraform destroy --force --state="$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/terraform.tfstate" "$KUBENOW_TERRAFORM_FOLDER"
