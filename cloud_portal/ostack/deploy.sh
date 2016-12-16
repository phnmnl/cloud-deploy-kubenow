#!/usr/bin/env bash
# set -e

# when testing you have to source: env_vars_expected_from_cloud_portal.sh

# set pwd
# cd "$PORTAL_APP_REPO_FOLDER/cloud_portal/ostack"

# presetup (generate key etc.)
$PORTAL_APP_REPO_FOLDER'/bin/pre-setup'

# hardcoded parameters
export PRIVATE_KEY="$PORTAL_APP_REPO_FOLDER/vre.key"
export TF_VAR_ssh_key="$PORTAL_APP_REPO_FOLDER/vre.key.pub"
export TF_VAR_cf_mail="anders.larsson@icm.uu.se"
export TF_VAR_cf_zone="uservice.se"
export TF_VAR_cf_subdomain=$TF_VAR_cluster_prefix
export TF_VAR_KuberNow_image="kubenow-release-01"

# generate kubeadm token
kubeadm_token=`$PORTAL_APP_REPO_FOLDER/KubeNow/generate_kubetoken.sh`
export TF_VAR_kubeadm_token=$kubeadm_token

# Deploy cluster with terraform
terraform get $PORTAL_APP_REPO_FOLDER'/KubeNow/openstack'
terraform apply --state=$PORTAL_DEPLOYMENTS_ROOT'/'$PORTAL_DEPLOYMENT_REFERENCE'/terraform.tfstate' $PORTAL_APP_REPO_FOLDER'/KubeNow/openstack'

# Provision nodes with ansible
export ANSIBLE_HOST_KEY_CHECKING=False
all_nodes_count=$(($TF_VAR_node_count+$TF_VAR_edge_count+1))
ansible_inventory_file=$PORTAL_APP_REPO_FOLDER'/cloud_portal/ostack/inventory'

# check that cluster is ready for deployment
ansible-playbook -i $ansible_inventory_file \
                 -e "all_nodes_count=$all_nodes_count" \
                 --key-file $PRIVATE_KEY \
                 $PORTAL_APP_REPO_FOLDER'/playbooks/wait_until_all_nodes_joined_master.yml'

# deploy core stack
ansible-playbook -i $ansible_inventory_file \
                 --key-file $PRIVATE_KEY \
                 -e "all_nodes_count=$all_nodes_count" \
                 -e "cf_mail=$TF_VAR_cf_mail" \
                 -e "cf_token=$TF_VAR_cf_token" \
                 -e "cf_zone=$TF_VAR_cf_zone" \
                 -e "cf_subdomain=$TF_VAR_cf_subdomain" \
                 $PORTAL_APP_REPO_FOLDER'/KubeNow/stacks/traefik-lb/main.yml'

# deploy gluster
ansible-playbook -i $ansible_inventory_file \
                 --key-file $PRIVATE_KEY \
                 $PORTAL_APP_REPO_FOLDER'/KubeNow/stacks/gluster-storage/main.yml'

# password for jupyter/luigi

# deploy jupyter/luigi

# deploy galaxy
domain=$TF_VAR_cf_subdomain$TF_VAR_cf_zone
ansible-playbook -i $ansible_inventory_file \
                 -e "domain=$domain" \
                 --key-file $PRIVATE_KEY \
                 $PORTAL_APP_REPO_FOLDER'/playbooks/galaxy.yml'



