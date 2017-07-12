#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
# (but allow for the error trap)
set -eE

function report_err() {
  # post deployment log to slack channel (only if portal deployment)
  if [[ ! -n "$LOCAL_DEPLOYMENT" ]]; then
    curl -F file="@$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/output.log" \
	     -F channels="portal-deploy-error" \
	     -F token="$SLACK_ERR_REPORT_TOKEN" \
	     https://slack.com/api/files.upload
  fi
}

# Trap errors
trap report_err ERR

# set pwd (to make sure all variable files end up in the deployment reference dir)
mkdir -p "$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE"
cd "$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE"

# presetup (generate key kubeadm token etc.)
"$PORTAL_APP_REPO_FOLDER/bin/pre-setup"
export TF_VAR_kubeadm_token=$(cat "$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/kubetoken")
export PRIVATE_KEY="$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/vre.key"
export TF_VAR_ssh_key="$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/vre.key.pub"

#
# hardcoded params (TODO move to params file)
#

# gce and ostack

IMG_VERSION="v031"
export TF_VAR_kubenow_image="kubenow-$IMG_VERSION"

# gce
# workaround: -the credentials are provided as an environment variable, but KubeNow terraform
# scripts need a file. Creates an credentialsfile from the environment variable
if [ -n "$GOOGLE_CREDENTIALS" ]; then
  printf '%s\n' "$GOOGLE_CREDENTIALS" > "$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/gce_credentials_file.json"
  export TF_VAR_gce_credentials_file="$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/gce_credentials_file.json"
fi

# gce - make sure image is available in google project
if [ "$KUBENOW_TERRAFORM_FOLDER" = "$PORTAL_APP_REPO_FOLDER/KubeNow/gce" ]
then
   ansible-playbook -e "credentials_file_path=\"$TF_VAR_gce_credentials_file\"" \
                    -e "img_version=$IMG_VERSION" \
                    "$PORTAL_APP_REPO_FOLDER/KubeNow/playbooks/import-gce-image.yml"
fi

# ostack
# make sure image is available in openstack
if [ "$KUBENOW_TERRAFORM_FOLDER" = "$PORTAL_APP_REPO_FOLDER/KubeNow/openstack" ] && [ -n "$LOCAL_DEPLOYMENT" ]
then
   ansible-playbook "$PORTAL_APP_REPO_FOLDER/KubeNow/playbooks/import-openstack-image.yml"
   #"$PORTAL_APP_REPO_FOLDER/bin/import-openstack-image.yml"
fi

# kvm
# make sure image is available in kvm
if [ "$KUBENOW_TERRAFORM_FOLDER" = "$PORTAL_APP_REPO_FOLDER/KubeNow/kvm" ]
then
   export KN_LOCAL_DIR="/.kubenow"
   export KN_IMAGE_NAME="$TF_VAR_kubenow_image"
   "$PORTAL_APP_REPO_FOLDER/KubeNow/bin/image-download-kvm.sh"
   export TF_VAR_kubenow_image="$TF_VAR_kubenow_image.qcow2"
fi

# gce and aws
export TF_VAR_master_disk_size="20"
export TF_VAR_node_disk_size="20"
export TF_VAR_edge_disk_size="20"
export TF_VAR_glusternode_disk_size="20"

# Deploy cluster with terraform
terraform get "$KUBENOW_TERRAFORM_FOLDER"
terraform apply --state="$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/terraform.tfstate" "$KUBENOW_TERRAFORM_FOLDER"

# Provision nodes with ansible
export ANSIBLE_HOST_KEY_CHECKING=False
ansible_inventory_file="$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/inventory"

# deploy KubeNow core stack
ansible-playbook -i "$ansible_inventory_file" \
                 --key-file "$PRIVATE_KEY" \
                 "$PORTAL_APP_REPO_FOLDER/KubeNow/playbooks/install-core.yml"

# wait for all pods in core stack to be ready
ansible-playbook -i "$ansible_inventory_file" \
                 --key-file "$PRIVATE_KEY" \
                 "$PORTAL_APP_REPO_FOLDER/playbooks/wait_for_all_pods_ready.yml"

# deploy heketi
ansible-playbook -i "$ansible_inventory_file" \
                 --key-file "$PRIVATE_KEY" \
                 "$PORTAL_APP_REPO_FOLDER/KubeNow/playbooks/install-heketi-gluster.yml"

# deploy phenomenal-pvc
ansible-playbook -i "$ansible_inventory_file" \
                 --key-file "$PRIVATE_KEY" \
                 -e "name=galaxy-pvc" \
                 -e "storage=95Gi" \
                 "$PORTAL_APP_REPO_FOLDER/KubeNow/playbooks/create-pvc.yml"

# deploy jupyter
ansible-playbook -i "$ansible_inventory_file" \
                 --key-file "$PRIVATE_KEY" \
                 -e "jupyter_chart_version=0.1.1" \
                 -e "jupyter_image_tag=:latest" \
                 -e "jupyter_password=$TF_VAR_jupyter_password" \
                 -e "jupyter_pvc=galaxy-pvc" \
                 -e "jupyter_resource_req_cpu=200m" \
                 -e "jupyter_resource_req_memory=1G" \
                 "$PORTAL_APP_REPO_FOLDER/playbooks/jupyter.yml"

# deploy luigi
ansible-playbook -i "$ansible_inventory_file" \
                 --key-file "$PRIVATE_KEY" \
                 "$PORTAL_APP_REPO_FOLDER/playbooks/luigi/main.yml"

# deploy kubernetes-dashboard
dashboard_auth=$(htpasswd -nb "$TF_VAR_dashboard_username" "$TF_VAR_dashboard_password")
dashboard_auth_base64=$(echo $dashboard_auth | base64)
ansible-playbook -i "$ansible_inventory_file" \
                 --key-file "$PRIVATE_KEY" \
                 -e "auth_base64=$dashboard_auth_base64" \
                 "$PORTAL_APP_REPO_FOLDER/playbooks/kubernetes-dashboard/main.yml"

# deploy galaxy
# first generate key
"$PORTAL_APP_REPO_FOLDER/bin/generate-galaxy-api-key"
galaxy_api_key=$(cat "$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/galaxy_api_key")
ansible-playbook -i "$ansible_inventory_file" \
                 --key-file "$PRIVATE_KEY" \
                 -e "galaxy_chart_version=latest" \
                 -e "galaxy_image_tag=:latest" \
                 -e "galaxy_admin_password=$TF_VAR_galaxy_admin_password" \
                 -e "galaxy_admin_email=$TF_VAR_galaxy_admin_email" \
                 -e "galaxy_api_key=$galaxy_api_key" \
                 -e "galaxy_pvc=galaxy-pvc" \
                 -e "postgres_pvc=false" \
                 "$PORTAL_APP_REPO_FOLDER/playbooks/galaxy.yml"

# wait until jupyter is up and do git clone data into the container
ansible-playbook -i "$ansible_inventory_file" \
                 --key-file "$PRIVATE_KEY" \
                 "$PORTAL_APP_REPO_FOLDER/playbooks/git_clone_mtbls233.yml"

# wait for jupyter notebook http response != Bad Gateway
ansible-playbook -i "$ansible_inventory_file" \
                 -e "name=notebook" \
                 "$PORTAL_APP_REPO_FOLDER/playbooks/wait_for_http_not_down.yml"

# wait for luigi http response != Bad Gateway
ansible-playbook -i "$ansible_inventory_file" \
                 -e "name=luigi" \
                 "$PORTAL_APP_REPO_FOLDER/playbooks/wait_for_http_not_down.yml"

# wait for galaxy http response 200 OK
ansible-playbook -i "$ansible_inventory_file" \
                 -e "name=galaxy" \
                 "$PORTAL_APP_REPO_FOLDER/playbooks/wait_for_http_ok.yml"

