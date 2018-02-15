# Cloud-deploy-kubenow

This repo contains the server code being executed by the PhenoMeNal web portal

The command line client for setting up a PhenoMeNal Virtual Research Environment has changed and are now located here: https://github.com/phnmnl/KubeNow-plugin

## Developer documentation

If you want to debug or test deploying cloud-deploy-kubenow locally, please see [developer-info.md](developer-info.md)


### Directories and files

    ├── cloud_portal            # This is where the cloud portal deploy.sh, destroy.sh and state.sh scripts
    │   │                       # are stored in subdirectories per cloud provider
    │   │
    │   ├── aws                 # Sub directories per cloud provider
    │   ├── gcp
    │   ├── ostack
    │   ├── azure
    │   └── shared              # The bulk part of the deploy.sh, destroy.sh and state.sh are identical between
    │                           # provides and is residing in a shared version of the scripts called from the
    │                           # provider speciffic scripts
    │
    │
    ├── KubeNow                 # This is the standard KubeNow git repo included as a git sub-module and this is
    │                           # where the terraform and default KubeNow ansible scripts reside (called from the
    │                           # deploy.sh, destroy.sh and state.sh scripts)
    │
    │
    ├── playbooks               # Ansible playbooks that are Phenomenal release speciffic and not included in the
    │                           # default KubeNow repository
    │
    │
    ├── bin                     # Utility script that are used in the deploy.sh, destroy.sh and state.sh scripts
    │
    │
    ├ manifest.json             # This is the TSI parameter file used to describe the setup
    │
    │
    ├ config.ostack.sh-template     # Includes vars expected to be provided from web-ui and only used for local deployment
    │
    │
    ├ config.aws.sh-template        # Amazon version of deployment vars
    │
    │
    ├ config.aws.sh-template        # Microsoft Azure version of deployment vars
    │
    │
    └ config.gcp.sh-template        # Google cloud version of deployment vars
