#!/usr/bin/env bash
set -e

# set pwd (to make sure all variable files end up in the deployment reference dir)
mkdir -p "$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE"
cd "$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE"

# presetup (generate key kubeadm token etc.)
# generate token
"$PORTAL_APP_REPO_FOLDER/bin/pre-setup"
export TF_VAR_kubeadm_token=$(cat "$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/kubeadm_token")
export PRIVATE_KEY="$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/vre.key"
export TF_VAR_ssh_key="$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/vre.key.pub"

# read cloudflare credentials from the cloned submodule private repo
if [ -f "$PORTAL_APP_REPO_FOLDER/phenomenal-cloudflare/cloudflare_token_phenomenal.cloud.sh" ]; then
   source "$PORTAL_APP_REPO_FOLDER/phenomenal-cloudflare/cloudflare_token_phenomenal.cloud.sh"
fi

#
# hardcoded params
#

# gce and ostack
export TF_VAR_kubenow_image="anders-kubenow-v030-pre-alpha-2"

# gce
# workaround: -the credentials are provided as an environment variable, but KubeNow terraform
# scripts need a file. Creates an credentialsfile from the environment variable
if [ -n "$GOOGLE_CREDENTIALS" ]; then
  echo $GOOGLE_CREDENTIALS > "$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/gce_credentials_file.json"
  export TF_VAR_gce_credentials_file="$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/gce_credentials_file.json"
fi

# gce - make sure image is available in google project
if [ $KUBENOW_TERRAFORM_FOLDER = "$PORTAL_APP_REPO_FOLDER/KubeNow/gce" ]
then
   ansible-playbook -e "credentials_file_path=\"$TF_VAR_gce_credentials_file\"" "$PORTAL_APP_REPO_FOLDER/KubeNow/playbooks/import-gce-image.yml"
fi

# ostack
# make sure image is available in openstack
if [ $KUBENOW_TERRAFORM_FOLDER = "$PORTAL_APP_REPO_FOLDER/KubeNow/openstack" ] && [ -n "$LOCAL_DEPLOYMENT" ]
then
   ansible-playbook "$PORTAL_APP_REPO_FOLDER/KubeNow/playbooks/import-openstack-image.yml"
fi

# gce and aws
export TF_VAR_master_disk_size="20"
export TF_VAR_node_disk_size="20"
export TF_VAR_edge_disk_size="20"
export TF_VAR_glusternode_disk_size="20"

# Deploy cluster with terraform
terraform get $KUBENOW_TERRAFORM_FOLDER
terraform apply --state="$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/terraform.tfstate $KUBENOW_TERRAFORM_FOLDER"

# Provision nodes with ansible
export ANSIBLE_HOST_KEY_CHECKING=False
ansible_inventory_file="$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/inventory"

# deploy KubeNow core stack
ansible-playbook -i $ansible_inventory_file \
                 --key-file $PRIVATE_KEY \
                 "$PORTAL_APP_REPO_FOLDER/KubeNow/playbooks/install-core.yml"

# wait for all pods in core stack to be ready
ansible-playbook -i $ansible_inventory_file \
                 --key-file $PRIVATE_KEY \
                 "$PORTAL_APP_REPO_FOLDER/playbooks/wait_for_all_pods_ready.yml"

# deploy phenomenal-pvc
ansible-playbook -i $ansible_inventory_file \
                 --key-file $PRIVATE_KEY \
                 "$PORTAL_APP_REPO_FOLDER/playbooks/phenomenal_pvc/main.yml"

# deploy jupyter
ansible-playbook -i $ansible_inventory_file \
                 -e "jupyter_chart_version=0.1.1" \
                 -e "jupyter_image_tag=:v387f29b6ca83_cv0.4.7" \
                 -e "jupyter_password=$TF_VAR_jupyter_password" \
                 -e "jupyter_pvc=galaxy-pvc" \
                 -e "jupyter_resource_req_cpu=200m" \
                 -e "jupyter_resource_req_memory=1G" \
                 --key-file $PRIVATE_KEY \
                 "$PORTAL_APP_REPO_FOLDER/playbooks/jupyter.yml"
                 
# deploy luigi
ansible-playbook -i $ansible_inventory_file \
                 --key-file $PRIVATE_KEY \
                 "$PORTAL_APP_REPO_FOLDER/playbooks/luigi/main.yml"

# deploy galaxy
# first generate key
"$PORTAL_APP_REPO_FOLDER/bin/generate-galaxy-api-key"
galaxy_api_key=$(cat "$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/galaxy_api_key")
ansible-playbook -i $ansible_inventory_file \
                 -e "galaxy_chart_version=0.1.6-phenomenal-alanine" \
                 -e "galaxy_image_tag=:v16.07-pheno_cv0.1.59" \
                 -e "galaxy_admin_password=$TF_VAR_galaxy_admin_password" \
                 -e "galaxy_admin_email=$TF_VAR_galaxy_admin_email" \
                 -e "galaxy_api_key=$galaxy_api_key" \
                 -e "galaxy_pvc=galaxy-pvc" \
                 -e "postgres_pvc=false" \
                 --key-file $PRIVATE_KEY \
                 "$PORTAL_APP_REPO_FOLDER/playbooks/galaxy.yml"
                                                              
# wait until jupyter is up and do git clone data into the container
ansible-playbook -i $ansible_inventory_file \
                 --key-file $PRIVATE_KEY \
                 "$PORTAL_APP_REPO_FOLDER/playbooks/git_clone_mtbls233.yml"
                                                       
# wait for jupyter notebook http response != Bad Gateway
ansible-playbook -i $ansible_inventory_file \
                 -e "name=jupyter-notebook" \
                 -e "url=http://notebook.$domain" \
                 "$PORTAL_APP_REPO_FOLDER/playbooks/wait_for_http_not_down.yml"
                 
# wait for luigi http response != Bad Gateway
ansible-playbook -i $ansible_inventory_file \
                 -e "name=luigi" \
                 -e "url=http://luigi.$domain" \
                 "$PORTAL_APP_REPO_FOLDER/playbooks/wait_for_http_not_down.yml"
                 
# wait for galaxy http response 200 OK
ansible-playbook -i $ansible_inventory_file \
                 -e "name=galaxy" \
                 -e "url=http://galaxy.$domain" \
                 "$PORTAL_APP_REPO_FOLDER/playbooks/wait_for_http_ok.yml"
