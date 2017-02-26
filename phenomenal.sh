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
    state       Status of the cre

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

case "$1" in
    deploy|destroy|state)
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

# set environment variables used by scripts in cloud-deploy/
export PORTAL_DEPLOYMENTS_ROOT="$PWD/deployments"
export PORTAL_APP_REPO_FOLDER="$PWD"
export PORTAL_DEPLOYMENT_REFERENCE="id-phnmnl-$provider"

deployment_dir="$PORTAL_DEPLOYMENTS_ROOT/$PORTAL_DEPLOYMENT_REFERENCE"
if [[ ! -d "$deployment_dir" ]]; then
    mkdir -p "$deployment_dir"
fi
printf 'Using deployment directory "%s"\n' "$deployment_dir"

command_and_path="./cloud_portal/$provider/$cmd.sh"
printf 'Executing "%s"...\n' "$command_and_path"
command "$command_and_path"

## finally display url:s
#domain="$TF_VAR_cf_subdomain.$TF_VAR_cf_zone"
#jupyter_url="http://notebook.$domain"
#luigi_url="http://luigi.$domain"
#galaxy_url="http://galaxy.$domain"
#
#echo 'Services should be reachable at following url:'
#printf 'Galaxy:  "%s"\n' "$galaxy_url"
#printf 'Jupyter: "%s"\n' "$jupyter_url"
#printf 'Luigi:   "%s"\n' "$luigi_url"
