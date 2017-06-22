#!/usr/bin/env bash

# Destroy everything
cd "$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE"

ansible_inventory_file="$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/inventory"

# TODO read this from deploy.sh file
export TF_VAR_kubenow_image="kubenow-v31"
export TF_VAR_kubeadm_token="fake.token"
export TF_VAR_master_disk_size="20"
export TF_VAR_node_disk_size="20"
export TF_VAR_edge_disk_size="20"
export TF_VAR_glusternode_disk_size="20"
export TF_VAR_ssh_key="$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/vre.key.pub"

terraform destroy --force --state="$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/terraform.tfstate" "$KUBENOW_TERRAFORM_FOLDER"
