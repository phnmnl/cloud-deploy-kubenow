#!/usr/bin/env bash

# Destroy everything
export KEY_PATH="/home/anders/projekt/phenomenal/ssh/cloud.key"

# remove cloudflare record
ansible_inventory_file=$PORTAL_APP_REPO_FOLDER'/cloud_portal/ostack/inventory'

echo $ansible_inventory_file
echo $PORTAL_APP_REPO_FOLDER'/KubeNow/playbooks/clean-cloudflare.yml'

ansible-playbook -i $ansible_inventory_file \
                 --key-file $KEY_PATH \
                 -e "cf_mail=$TF_VAR_cf_mail" \
                 -e "cf_token=$TF_VAR_cf_token" \
                 -e "cf_zone=$TF_VAR_cf_zone" \
                 -e "cf_subdomain=$TF_VAR_cf_subdomain" $PORTAL_APP_REPO_FOLDER'/KubeNow/playbooks/clean-cloudflare.yml'

export TF_VAR_KuberNow_image=""
export TF_VAR_kubeadm_token=""
export TF_VAR_ssh_key=$KEY_PATH
terraform destroy --force --state=$PORTAL_DEPLOYMENTS_ROOT'/'$PORTAL_DEPLOYMENT_REFERENCE'/terraform.tfstate' $PORTAL_APP_REPO_FOLDER'/KubeNow/openstack'


