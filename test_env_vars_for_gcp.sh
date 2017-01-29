#
# These vars are expected to be set in web-ui (specified via manifest.sh)
#

#
# Speciffic for GCE
#
#
# Apart from following variables env-var GOOGLE_CREDENTIALS is supposed to be set
#

export GOOGLE_CREDENTIALS=$(cat "/path/to/credentials_file.json");
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

# Galaxy
export TF_VAR_galaxy_admin_email="yoourname@bla.bla.com"
export TF_VAR_galaxy_admin_password="password"

# Jupyter
export TF_VAR_jupyter_password="password"

#
# General for TSI
#

#
# If you are doing a local testing replace the path with the absolute
# path to your local cloned cloud-deploy directory
#
export PORTAL_DEPLOYMENTS_ROOT="/home/xxxxxxxxxxxxxxxxxxx/cloud-deploy/deployments"
export PORTAL_APP_REPO_FOLDER="/home/xxxxxxxxxxxxxxx/cloud-deploy"
export PORTAL_DEPLOYMENT_REFERENCE="id-phnmnl-gcp"

# local testing - make sure deployment-id directory exists
dir=$PORTAL_DEPLOYMENTS_ROOT'/'$PORTAL_DEPLOYMENT_REFERENCE
if [ ! -d $dir ]; then
  mkdir -p $dir
fi
