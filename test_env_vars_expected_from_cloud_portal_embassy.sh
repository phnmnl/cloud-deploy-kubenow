#
# These vars are set in web-ui (via manifest.sh)
#

#
# Cloud speciffic
#
export TF_VAR_floating_ip_pool="net_external"
export TF_VAR_external_network_uuid="d9384930-baa5-422b-8657-1d42fb54f89c"

#
# General
#
export TF_VAR_master_flavor="s1.large"
export TF_VAR_node_flavor="s1.large"
export TF_VAR_edge_flavor="s1.large"

export TF_VAR_cluster_prefix="vrembassy"
export TF_VAR_node_count="2"
export TF_VAR_edge_count="2"

export TF_VAR_cf_mail="xxxxxxxx"
export TF_VAR_cf_token="xxxxxxxxx"
export TF_VAR_cf_zone="xxxxxxxxx"
export TF_VAR_cf_subdomain=$TF_VAR_cluster_prefix


#
# These vars are set in web-ui (via manifest.sh)
#
export PORTAL_DEPLOYMENTS_ROOT="/home/xxxxxxxxxxxx/cloud-deploy/deployments"
export PORTAL_APP_REPO_FOLDER="/home/xxxxxxxxxx/cloud-deploy"
export PORTAL_DEPLOYMENT_REFERENCE="id-phnmnl-embassy"

# make sure deploymend id dir exists
mkdir $PORTAL_DEPLOYMENTS_ROOT'/'$PORTAL_DEPLOYMENT_REFERENCE

