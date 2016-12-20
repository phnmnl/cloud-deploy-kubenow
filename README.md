# cloud-deploy-kubenow
This repository contains one-click-deploy-scripts to setup the PhenoMeNal cloud VRE.
The scripts are designed to work with the EMBL-EBI-TSI - Phenomenal Web-UI.

This repository contains submodules so use the `--recursive` parameter when cloning e.g.

 `git clone --recursive ....`

### Directories and files

    ├── cloud_portal            # This is where the cloud portal deploy.sh, destroy.sh and state.sh scripts 
    │   │                       # are stored in subdirectories per cloud provider
    │   │
    │   ├── aws                 # Sub directories per cloud provider
    │   ├── gcp
    │   ├── ostack
    │   └── shared              # The bulk part of the deploy.sh, destroy.sh and state.sh are identical between
    │                           # provides and is residing in a shared version of the scripts called from the
    │                           # provider speciffic scripts
    │
    │
    ├── KubeNow                 # This is the standart KubeNow git repo included as a git sub-module and this is
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
    ├── phenomenal-cloudflare   # This is a private git repository as a submodule storing cloudflare secret token
    │
    │
    │
    ├ manifest.json             # This is the TSI parameter file used to describe the setup
    │
    │
    └ test_env_vars_expected_from_cloud_portal_embassy.sh      # Includes vars expected to be provided from web-ui
                                                               # and only used for local testing purposes 
