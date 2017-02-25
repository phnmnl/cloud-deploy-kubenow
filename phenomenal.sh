#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

PROVIDERS=(aws gcp ostack)
COMMANDS=(deploy destroy state)
scriptname=`basename "$0"`

function display_help
{	
    echo "usage: $scriptname <command> <provider> [options]"
    echo
    display_commands
    display_providers
    echo 
    echo "options:"
    echo " -c, --config-file       user provided config file"
    echo
    echo "examples: ./$scriptname deploy ostack" 
    echo "          ./$scriptname destroy ostack"
    echo "          ./$scriptname state gce" 
    echo "          ./$scriptname deploy gce --config-file ~/my-configs/my-cloud-conf" 
}

function display_commands
{	
	echo "supported <command> are: ${COMMANDS[@]}"
}

function display_providers
{	
	echo "supported <provider> are: ${PROVIDERS[@]}"
}

function contains_element
{
    local e
    for e in "${@:2}"; do
        [ "$e" = "$1" ] && return 0
    done
    return 1
}

if [ -z "$1" ]; then
    echo "no <command> specified"
    echo
    display_help
    exit 1
fi

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    display_help
    exit 1
fi

if ! contains_element "$1" "${COMMANDS[@]}"; then
    echo "'$1' is not a valid <command>"
    display_commands
    exit 1
fi
command="$1"

if [ -z "$2" ]; then
    echo "no <provider> specified"
    echo
    display_help
    exit 1
fi

if ! contains_element "$2" "${PROVIDERS[@]}"; then
    echo "'$2' is not a valid <provider> argument"
    display_providers
    exit 1
fi
provider="$2"

if [ -z "$3" ]; then
    config_file="config.$provider.sh"
    echo "no configuration file specified, using default: $config_file"
elif [ "$3" = "-c" ] || [ "$3" = "--config-file" ]; then
    config_file="$4"
    echo "using config-file: $config_file"
else
    echo "'$3' is not a valid argument"
    echo "see: '$scriptname --help'"
    exit 1
fi

if [ ! -f "$config_file" ]; then
    echo "config file does not exist"
    exit 1
fi
source "$config_file"

# set environment variables used by scripts in cloud-deploy/
export PORTAL_DEPLOYMENTS_ROOT="$PWD/deployments"
export PORTAL_APP_REPO_FOLDER="$PWD"
export PORTAL_DEPLOYMENT_REFERENCE="id-phnmnl-$provider"

deployment_dir=$PORTAL_DEPLOYMENTS_ROOT'/'$PORTAL_DEPLOYMENT_REFERENCE
echo "deployment-dir: $deployment_dir"
if [ ! -d $deployment_dir ]; then
    mkdir -p $deployment_dir
fi

command_and_path="./cloud_portal/$provider/$command.sh"
echo "command: $command_and_path"
"$command_and_path"

