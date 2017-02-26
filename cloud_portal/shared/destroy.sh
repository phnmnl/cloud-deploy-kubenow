#!/usr/bin/env bash

# Destroy everything
cd $PORTAL_DEPLOYMENTS_ROOT'/'$PORTAL_DEPLOYMENT_REFERENCE

# remove cloudflare record
# read cloudflare credentials from the cloned submodule private repo
# read cloudflare credentials from the cloned submodule private repo
if [ -z "$TF_VAR_cf_token" ]; then
   source $PORTAL_APP_REPO_FOLDER'/'phenomenal-cloudflare/cloudflare_token_phenomenal.cloud.sh
fi
TF_VAR_cf_subdomain=$TF_VAR_cluster_prefix
ansible_inventory_file=$PORTAL_DEPLOYMENTS_ROOT'/'$PORTAL_DEPLOYMENT_REFERENCE'/inventory'

ansible-playbook -i $ansible_inventory_file \
                 -e "cf_mail=$TF_VAR_cf_mail" \
                 -e "cf_token=$TF_VAR_cf_token" \
                 -e "cf_zone=$TF_VAR_cf_zone" \
                 -e "cf_subdomain=$TF_VAR_cf_subdomain" $PORTAL_APP_REPO_FOLDER'/KubeNow/playbooks/clean-cloudflare.yml'

export TF_VAR_KuberNow_image="kube-release-01"
export TF_VAR_kubenow_image_id="ami-fake-id"
export TF_VAR_kubeadm_token="fake.token"
export TF_VAR_master_disk_size="50"
export TF_VAR_node_disk_size="50"
export TF_VAR_edge_disk_size="50"
export TF_VAR_ssh_key=$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE'/vre.key.pub'
terraform destroy --force --state=$PORTAL_DEPLOYMENTS_ROOT'/'$PORTAL_DEPLOYMENT_REFERENCE'/terraform.tfstate' $KUBENOW_TERRAFORM_FOLDER
