#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
# (but allow for the error trap)
set -eE

function report_err() {

  # post deployment log to slack channel (only if portal deployment)
  if [[ ! -n "$LOCAL_DEPLOYMENT" ]]; then

    # Add some debug info
    echo "TF_VAR_client_id=$TF_VAR_client_id"
    echo "TF_VAR_aws_access_key_id=$TF_VAR_aws_access_key_id"
    echo "OS_PROJECT_ID=$OS_PROJECT_ID"
    echo "OS_PROJECT_NAME=$OS_PROJECT_NAME"
    echo "TF_VAR_gce_project=$TF_VAR_gce_project"

    # Debug OS-vars (skip secrets)
    env | grep OS_ | grep -v -e PASSWORD -e TOKEN -e OS_RC_FILE -e pass -e Pass -e PASS

    # Debug TF-vars (skip secrets)
    env | grep TF_VAR_ | grep -v -e PASSWORD -e TOKEN -e secret -e GOOGLE_CREDENTIALS -e aws_secret_access_key -e pass -e Pass -e PASS

    curl -F file="@$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/output.log" \
         -F filename="output-$PORTAL_DEPLOYMENT_REFERENCE.log" \
         -F filetype="shell" \
	     -F channels="portal-deploy-error" \
	     -F token="$SLACK_ERR_REPORT_TOKEN" \
	     https://slack.com/api/files.upload
  fi
}

function parse_and_export_vars() {
  input_file="$1"

  while IFS= read -r line; do
    [[ "$line" =~ ^export ]] || continue # skip non-export lines

    line=${line#export }        # remove "export " from start of line
    line=${line%%#*}            # strip comment (if any)

    case $line in
      *=*)
        var=${line%%=*}
        case $var in
            *[!A-Z_a-z]*)
                echo "Warning: invalid variable name $var ignored" >&2
                continue ;;
        esac

        line=${line#*=}
        line="${line%\"}"       # remove trailing "
        line="${line#\"}"       # remove starting "
        line="${line%\'}"       # remove trailing '
        line="${line#\'}"       # remove starting '
        echo eval export $var='"$line"'
        eval export $var='"$line"'
    esac
  done <"$input_file"
}

# Trap errors
trap report_err ERR

git hash-object "$PORTAL_APP_REPO_FOLDER/cloud_portal/shared/deploy.sh"

# set pwd (to make sure all variable files end up in the deployment reference dir)
mkdir -p "$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE"
cd "$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE"

# read portal secrets from private repo
if [ -z "$LOCAL_DEPLOYMENT" ]; then
   if [ ! -d "$PORTAL_APP_REPO_FOLDER/phenomenal-cloudflare" ]; then
      git clone git@github.com:EMBL-EBI-TSI/phenomenal-cloudflare.git "$PORTAL_APP_REPO_FOLDER/phenomenal-cloudflare"
   fi
   source "$PORTAL_APP_REPO_FOLDER/phenomenal-cloudflare/cloudflare_token_phenomenal.cloud.sh"
   export TF_VAR_use_cloudflare="true"
   export SLACK_ERR_REPORT_TOKEN=$(cat "$PORTAL_APP_REPO_FOLDER/phenomenal-cloudflare/slacktoken")
   export USE_VIRTUAL_ENV="true"
fi

# presetup (generate key kubeadm token etc.)
"$PORTAL_APP_REPO_FOLDER/bin/pre-setup"

# overwrite ssh-key with debug key from private repo if specified
if [ "$use_debug_key" = "true" ]; then
  cp "$PORTAL_APP_REPO_FOLDER/phenomenal-cloudflare/portal-debug-key" "$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/vre.key"
  cp "$PORTAL_APP_REPO_FOLDER/phenomenal-cloudflare/portal-debug-key.pub" "$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/vre.key.pub"
fi

export TF_VAR_kubeadm_token=$(cat "$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/kubetoken")
export PRIVATE_KEY="$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/vre.key"
export TF_VAR_ssh_key="$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/vre.key.pub"

# hardcoded params (TODO move to params file)
export IMG_VERSION="v050"
export TF_VAR_boot_image="kubenow-$IMG_VERSION"
export ARM_CLIENT_ID="$TF_VAR_client_id"
export ARM_CLIENT_SECRET="$TF_VAR_client_secret"
export ARM_TENANT_ID="$TF_VAR_tenant_id"
export ARM_LOCATION="$TF_VAR_location"
export TF_VAR_master_disk_size="20"
export TF_VAR_node_disk_size="20"
export TF_VAR_edge_disk_size="20"
export TF_VAR_glusternode_disk_size="20"
if [ -z $TF_VAR_phenomenal_pvc_size ]; then
  TF_VAR_phenomenal_pvc_size="90Gi"
fi
#if [ -z $TF_VAR_dns_nameservers ]; then
#  TF_VAR_dns_nameservers=""
#fi


# gce
# workaround: -the credentials are provided as an environment variable, but KubeNow terraform
# scripts need a file. Creates an credentialsfile from the environment variable
if [ -n "$GOOGLE_CREDENTIALS" ]; then
  printf '%s\n' "$GOOGLE_CREDENTIALS" > "$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/gce_credentials_file.json"
  export TF_VAR_gce_credentials_file="$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/gce_credentials_file.json"
fi

# upload images
if [ "$PROVIDER" = "gce" ]; then
   export KN_IMAGE_NAME="$TF_VAR_boot_image"
   ansible-playbook -e "credentials_file_path=\"$TF_VAR_gce_credentials_file\"" \
                    -e "img_version=$IMG_VERSION" \
                    "$PORTAL_APP_REPO_FOLDER/KubeNow/playbooks/import-gce-image.yml"

elif [ "$PROVIDER" = "openstack" ]; then
  export KN_IMAGE_NAME="$TF_VAR_boot_image"
  # always use virtualenv for now
  export USE_VIRTUAL_ENV="true"

  # print env-var into file
  if [ -n "$OS_RC_FILE" ]; then
    echo "$OS_RC_FILE" | base64 --decode > "$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/os-credentials.rc"
    parse_and_export_vars "$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/os-credentials.rc"
  fi

  # Use virtualenv to install glance without compiling - after download with glance - disable it again
  if [ -n "$USE_VIRTUAL_ENV" ]; then
     curl -L "https://drive.google.com/uc?export=download&id=1G68tJCsIYMIp1s41GhCqtgtbSS2SlBNM" > netifaces_wheelhouse.zip
     unzip -o netifaces_wheelhouse.zip
     virtualenv deploy
     source deploy/bin/activate
     pip install -U pip
     pip install --no-index --find-links=netifaces_wheelhouse netifaces
     pip install -r "$PORTAL_APP_REPO_FOLDER/requirements_glance.txt" --no-deps
     # print version
     glance --version
  fi

  # Upload image to openstack installation if not there
  "$PORTAL_APP_REPO_FOLDER/KubeNow/bin/image-create-openstack.sh"

  # Enough with this virtualenv
  if [ -n "$USE_VIRTUAL_ENV" ]; then
     deactivate
  fi

elif [ "$PROVIDER" = "azure" ]; then
  #export KN_IMAGE_NAME="$TF_VAR_boot_image"
  #"$PORTAL_APP_REPO_FOLDER/KubeNow/bin/image-create-azure.sh"
  echo "Azure is not supported by this version of cloud-deploy, exiting"
  exit 1

elif [ "$PROVIDER" = "kvm" ]; then
   echo "KVM is not supported by this version of cloud-deploy, exiting"
  exit 1
fi

# Add terraform to path (TODO) remove this portal workaround eventually
export PATH=/usr/lib/terraform_0.10.7:$PATH

# Different config depending on wether it is proxied or not
if [ "$TF_VAR_cloudflare_proxied" = "true" ]; then
   jupyter_hostname="notebook-$TF_VAR_cluster_prefix"
   luigi_hostname="luigi-$TF_VAR_cluster_prefix"
   dashboard_hostname="dashboard-$TF_VAR_cluster_prefix"
   galaxy_hostname="galaxy-$TF_VAR_cluster_prefix"
   export TF_VAR_cloudflare_record_texts="[\"$jupyter_hostname\",\"$luigi_hostname\",\"$dashboard_hostname\",\"$galaxy_hostname\"]"
else
   jupyter_hostname="notebook"
   luigi_hostname="luigi"
   dashboard_hostname="dashboard"
   galaxy_hostname="galaxy"
   export TF_VAR_cloudflare_subdomain="$TF_VAR_cluster_prefix"
   export TF_VAR_cloudflare_record_texts='["galaxy","notebook","luigi","dashboard"]'
fi

# Deploy cluster with terraform
if [ -n "$TF_skip_deployment" ]; then
   echo "Skip deployment option specified"
else
   KUBENOW_TERRAFORM_FOLDER="$PORTAL_APP_REPO_FOLDER/KubeNow/$PROVIDER"
   terraform init "$KUBENOW_TERRAFORM_FOLDER"
   terraform apply --parallelism=50 --state="$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/terraform.tfstate" "$KUBENOW_TERRAFORM_FOLDER"
fi

# Skip provisioning if specified
if [ -n "$TF_skip_provisioning" ]; then
   echo "Skip provisioning option specified, exiting"
   exit 0
fi


# Provision with ansible
export ANSIBLE_HOST_KEY_CHECKING=False
ansible_inventory_file="$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE/inventory"
export LOG_ALL="true"

# Setup vars
if [ -n "$LOCAL_DEPLOYMENT" ] || [ -n "$LOG_ALL"  ]; then
   no_sensitive_logging=false
else
   no_sensitive_logging=true
fi

# dashboard auth
hashed_password=$(openssl passwd -apr1 "$TF_VAR_dashboard_password")
dashboard_auth=$(printf "$TF_VAR_dashboard_username":"$hashed_password")

# deploy KubeNow core stack
ansible-playbook -i "$ansible_inventory_file" \
                 --key-file "$PRIVATE_KEY" \
                 "$PORTAL_APP_REPO_FOLDER/KubeNow/playbooks/install-core.yml"

# deploy heketi as default

# deploy phenomenal pvc
ansible-playbook -i "$ansible_inventory_file" \
                   --key-file "$PRIVATE_KEY" \
                   -e "name=galaxy-pvc" \
                   -e "storage=$TF_VAR_phenomenal_pvc_size" \
                   -e "$storage_class" \
                   "$PORTAL_APP_REPO_FOLDER/KubeNow/playbooks/create-pvc.yml"

# deploy phenomenal
ansible-playbook -i "$ansible_inventory_file" \
                 --key-file "$PRIVATE_KEY" \
                 -e "jupyter_include=true" \
                 -e "jupyter_chart_version=0.1.2" \
                 -e "jupyter_hostname=$jupyter_hostname" \
                 -e "jupyter_image_tag=:latest" \
                 -e "jupyter_password=$TF_VAR_jupyter_password" \
                 -e "jupyter_pvc=galaxy-pvc" \
                 -e "jupyter_resource_req_cpu=200m" \
                 -e "jupyter_resource_req_memory=1G" \
                 -e "jupyter_nologging=$no_sensitive_logging" \
                 -e "luigi_include=true" \
                 -e "luigi_hostname=$luigi_hostname" \
                 -e "luigi_resource_req_cpu=200m" \
                 -e "luigi_resource_req_memory=1G" \
                 -e "dashboard_include=true" \
                 -e "dashboard_basic_auth=$dashboard_auth" \
                 -e "dashboard_hostname=$dashboard_hostname" \
                 -e "dashboard_nologging=$no_sensitive_logging" \
                 -e "galaxy_include=true" \
                 -e "galaxy_chart_version=0.3.5" \
                 -e "galaxy_hostname=$galaxy_hostname" \
                 -e "galaxy_image_tag=:rc_v17.09-pheno-lr_cv1.6.162" \
                 -e "galaxy_admin_password=$TF_VAR_galaxy_admin_password" \
                 -e "galaxy_admin_email=$TF_VAR_galaxy_admin_email" \
                 -e "galaxy_pvc=galaxy-pvc" \
                 -e "galaxy_postgres_pvc=false" \
                 -e "galaxy_nologging=$no_sensitive_logging" \
                 "$PORTAL_APP_REPO_FOLDER/playbooks/install-phenomenal.yml"
