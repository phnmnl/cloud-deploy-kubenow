# cloud-deploy-kubenow
This repository contains one-click-deploy-scripts to setup the PhenoMeNal cloud CRE.
The scripts are also part of the backend of the [Phenonemmal Portal](http://portal.phenomenal-h2020.eu/cloud-research-environment)


This repository contains submodules so use the `--recursive` parameter when cloning e.g.

    git clone --recursive https://github.com/phnmnl/cloud-deploy-kubenow.git
 
 **Note:** You might get an error message: `fatal: clone of 'git@github.com:EMBL-EBI-TSI/phenomenal-cloudflare.git'
  into submodule path 'phenomenal-cloudflare' failed`. This is because you don't have the access rights to read the
  private repository containing secret api keys (this is an error you should ignore if you are deploying your own instance
  of the research environment)
 
If you later want to pull latest version and also pull latest submodule updates:

    git pull --recurse-submodules
    git submodule update --recursive --remote
 

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
    ├── phenomenal-cloudflare   # This is a private git repository as a submodule storing cloudflare secret token
    │
    │
    │
    ├ manifest.json             # This is the TSI parameter file used to describe the setup
    │
    │
    ├ test_env_vars_for_embassy.sh     # Includes vars expected to be provided from web-ui and only used for local
    │                                  # testing purposes
    │
    ├ test_env_vars_for_aws.sh         # Amazon version of testing vars       
    │
    │
    └ test_env_vars_for_gcp.sh         # Google cloud version of testing vars                                     


  
### If you want to test the deployment:

First, If you don't have a "kubenow-v020a1" image available in your cloud teenancy then you need to upload one.

Latest images are availabe for upload into your teenancy from: [https://github.com/kubenow/KubeNow/releases](https://github.com/kubenow/KubeNow/releases)
    
    # Now edit the file test_env_vars_for_xxx.sh  matching your cloudprovider (e.g. Openstack, Amazon, Google, Vagrant(local-deployment))
    
    # Then inject variables into your environment
    source test_env_vars_for_xxxx.sh
    
    # Deploy (openstack)
    cloud_portal/ostack/deploy.sh
    
    # Status
    cloud_portal/ostack/state.sh
    
Access services:
    
- http://galaxy. "your prefix" .phenomenal.cloud
    
- http://notebook. "your prefix" .phenomenal.cloud (password=password)
    
Destroy cluster:
    
    # Destroy
    cloud_portal/ostack/destroy.sh
