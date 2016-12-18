#
# These vars are set in web-ui (via manifest.sh)
#

#
# For AWS
#
export TF_VAR_aws_access_key_id="xxxxxxx"
export TF_VAR_aws_secret_access_key="xxxxxxxx"
export TF_VAR_aws_region="eu-central-1"
export TF_VAR_availability_zone="eu-central-1a"

export TF_VAR_master_instance_type="t2.medium"
export TF_VAR_node_instance_type="t2.medium"
export TF_VAR_edge_instance_type="t2.medium"

#
# General
#
export TF_VAR_cluster_prefix="vreaws"
export TF_VAR_node_count="2"
export TF_VAR_edge_count="1"

export TF_VAR_cf_mail="xxxxxxxx"
export TF_VAR_cf_token="xxxxxxxx"
export TF_VAR_cf_zone="uservice.se"
export TF_VAR_cf_subdomain=$TF_VAR_cluster_prefix

#
# These vars are set in web-ui (via manifest.sh)
#
export PORTAL_DEPLOYMENTS_ROOT="/home/..bla.../cloud-deploy/deployments"
export PORTAL_APP_REPO_FOLDER="/home/..bla.../cloud-deploy"
export PORTAL_DEPLOYMENT_REFERENCE="id-phnmnl-aws"

# make sure deploymend id dir exists
mkdir $PORTAL_DEPLOYMENTS_ROOT'/'$PORTAL_DEPLOYMENT_REFERENCE

