#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

scriptname="${BASH_SOURCE##*/}"

function usage
{
    cat <<TEXT_END
Usage:

    $scriptname -h
    $scriptname <command> <provider> [-c file]

Options:

    -h/--help   Display help
    -c/--config Use specified configuration file.  If no configuration
                file is specified, use default "config.<provider>.sh"

Commands:

    deploy      Setup the cloud research environment
    destroy     Destroy the cloud research environment
    state       Status of the cloud research environment
    list        List network and flavor-names for the cloud provider

Providers:

    aws
    gcp
    ostack

Examples:

    $scriptname deploy ostack
    $scriptname destroy ostack
    $scriptname state gcp
    $scriptname deploy gcp --config-file ~/my-configs/my-cloud-conf

TEXT_END
}

# dockoer --version | grep "Docker version" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Docker is not installed - exiting" >&2
    exit 1
fi

case "$1" in
    deploy|destroy|state|list)
        cmd="$1"
        ;;
    -h|--help)
        usage
        exit
        ;;
    "")
        echo "No <command> specified" >&2
        printf 'See "%s --help"\n' "$scriptname" >&2
        exit 1
        ;;
    *)
        printf '"%s" is not a valid command\n' "$1" >&2
        printf 'See "%s --help"\n' "$scriptname" >&2
        exit 1
        ;;
esac

case "$2" in
    aws|gcp|ostack)
        provider="$2"
        ;;
    "")
        echo "No <provider> specified" >&2
        printf 'See "%s --help"\n' "$scriptname" >&2
        exit 1
        ;;
    *)
        printf '"%s" is not a valid provider\n' "$2" >&2
        printf 'See "%s --help"\n' "$scriptname" >&2
        exit 1
        ;;
esac

config_file="config.$provider.sh"
case "$3" in
    -c|--config*)
        printf 'Using configuration file "%s"\n' "$4"
        config_file="$4"
        ;;
    "")
        printf 'Using default configuration file "%s"\n' "$config_file"
        ;;
    *)
        printf '"%s" is not a valid argument\n' "$3" >&2
        printf 'See "%s --help"\n' "$scriptname" >&2
        exit 1
        ;;
esac

if [[ ! -f "$config_file" ]]; then
    printf 'Configuration file "%s" does not exist\n' "$config_file" >&2
    exit 1
fi



source "$config_file"

if [ -n "$TF_VAR_gce_credentials_file" ]; then
  GOOGLE_CREDENTIALS=$(cat "$TF_VAR_gce_credentials_file")
fi

if [ -n "$OS_CREDENTIALS_FILE" ]; then
  # Import credentials file if variables not set aleady
  if [[ -z "$OS_USERNAME" ]] || [[ -z "$OS_PASSWORD" ]] || [[ -z "$OS_AUTH_URL" ]]; then
      source "$OS_CREDENTIALS_FILE"
  fi
fi

# set environment variables used by scripts in cloud-deploy/
DEPLOYMENTS_DIR="deployments"
DEPLOYMENT_REFERENCE="id-phnmnl-${config_file%.sh}"
DEPLOYMENT_DIR_HOST="$PWD/$DEPLOYMENTS_DIR/$DEPLOYMENT_REFERENCE"

printf 'Using deployment directory "%s"\n' "$DEPLOYMENT_DIR_HOST"

# execute scripts via docker container with all dependencies
# kubenow/provisioners:current \
docker run --rm -it \
  -v "$PWD":/cloud-deploy \
  -e "PORTAL_APP_REPO_FOLDER=/cloud-deploy" \
  -e "PORTAL_DEPLOYMENTS_ROOT=/cloud-deploy/$DEPLOYMENTS_DIR" \
  -e "PORTAL_DEPLOYMENT_REFERENCE=$DEPLOYMENT_REFERENCE" \
  -e "GOOGLE_CREDENTIALS=$GOOGLE_CREDENTIALS" \
  --env-file <(env | grep OS_) \
  --env-file <(env | grep TF_VAR_) \
  --entrypoint "/bin/bash" \
  andersla/provisioners:latest \
  -c "cd /cloud-deploy;/cloud-deploy/cloud_portal/$provider/$cmd.sh"

if [[ $cmd == "deploy" || $cmd == "state" ]]; then

  # display inventoty
  echo "Inventory:"
  cat "$DEPLOYMENT_DIR_HOST/inventory"
  echo "---"
  echo ""

  # get domain from inventory
  domain="$(awk -F'=' '/domain/ { print $2 }' $DEPLOYMENT_DIR_HOST/inventory)"

  ## finally display url:s
  jupyter_url="http://notebook.$domain"
  luigi_url="http://luigi.$domain"
  galaxy_url="http://galaxy.$domain"
  dashboard_url="http://dashboard.$domain"

  echo 'Services should be reachable at following url:'
  printf 'Galaxy:         "%s"\n' "$galaxy_url"
  printf 'Jupyter:        "%s"\n' "$jupyter_url"
  printf 'Luigi:          "%s"\n' "$luigi_url"
  printf 'Kube-dashboard: "%s"\n' "$dashboard_url"

fi
