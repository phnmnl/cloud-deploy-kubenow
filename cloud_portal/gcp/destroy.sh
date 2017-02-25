#!/usr/bin/env bash

# provider speciffic
export KUBENOW_TERRAFORM_FOLDER=$PORTAL_APP_REPO_FOLDER'/KubeNow/gce'

# workaround: -the credentials are provided as an environment variable, but KubeNow terraform
# scripts need a file.
if [ -n "$GOOGLE_CREDENTIALS" ]; then
  echo $GOOGLE_CREDENTIALS > $PORTAL_DEPLOYMENTS_ROOT'/'$PORTAL_DEPLOYMENT_REFERENCE'/gce_credentials_file.json'
  export TF_VAR_gce_credentials_file=$PORTAL_DEPLOYMENTS_ROOT'/'$PORTAL_DEPLOYMENT_REFERENCE'/gce_credentials_file.json'
fi

$PORTAL_APP_REPO_FOLDER'/cloud_portal/shared/destroy.sh'


# workaround: -the credentials are provided as an environment variable, but KubeNow terraform
# scripts need a file
rm $PORTAL_DEPLOYMENTS_ROOT'/'$PORTAL_DEPLOYMENT_REFERENCE'/gce_credentials_file.json'
