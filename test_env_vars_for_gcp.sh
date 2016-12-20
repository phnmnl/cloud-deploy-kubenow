#
# These vars are expected to be set in web-ui (specified via manifest.sh)
#

#
# Speciffic for GCE
#
export TF_VAR_gce_credentials_file="/home/xxxxxxxxxxxxxxxxxxxxxxxxxx.json"
export TF_VAR_gce_project="resolute-winter"
export TF_VAR_gce_zone="europe-west1-b"

#
# General (flavor names are speciffic for each openstack installation)
#
export TF_VAR_master_flavor="n1-standard-2"
export TF_VAR_node_flavor="n1-standard-2"
export TF_VAR_edge_flavor="n1-standard-2"

export TF_VAR_cluster_prefix="vregoogle"
export TF_VAR_node_count="2"
export TF_VAR_edge_count="1"

export TF_VAR_cf_mail="anders.larsson@icm.uu.se"
export TF_VAR_cf_token="xxxxxxxxxxx"
export TF_VAR_cf_zone="uservice.se"
export TF_VAR_cf_subdomain=$TF_VAR_cluster_prefix

#
# General for TSI
#
export PORTAL_DEPLOYMENTS_ROOT="/home/xxxxxxxxxxxxxxxxxxx/cloud-deploy/deployments"
export PORTAL_APP_REPO_FOLDER="/home/xxxxxxxxxxxxxxx/cloud-deploy"
export PORTAL_DEPLOYMENT_REFERENCE="id-phnmnl-gcp"

# local testing - make sure deploymend id dir exists
mkdir $PORTAL_DEPLOYMENTS_ROOT'/'$PORTAL_DEPLOYMENT_REFERENCE
