# cloud-deploy-kubenow
This repository contains one-click-deploy-scripts to setup the PhenoMeNal cloud CRE.
The scripts are also part of the backend of the [Phenonemmal Portal](http://portal.phenomenal-h2020.eu/cloud-research-environment)

This repository contains submodules so use the `--recursive` parameter when cloning e.g.

    git clone --recursive https://github.com/phnmnl/cloud-deploy-kubenow.git

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
    ├ manifest.json             # This is the TSI parameter file used to describe the setup
    │
    │
    ├ config.openstack.sh-template     # Includes vars expected to be provided from web-ui and only used for local deployment
    │
    │
    ├ config.aws.sh-template           # Amazon version of deployment vars
    │
    │
    └ config.gcp.sh-template           # Google cloud version of deployment vars



### If you want to test the deployment:

First, If you don't have a "kubenow-v020a1" image available in your cloud tenancy then you need to upload one. In the [KubeNow guidelines](https://kubenow.readthedocs.io/en/latest/developers/build-img.html) you can also find further details on how to build and upload a KubeNow image in your cloud tenancy.

Nonetheless, latest images are availabe for upload into your teenancy from: [https://github.com/kubenow/KubeNow/releases](https://github.com/kubenow/KubeNow/releases)

The next step is to make sure that you have the necessary credentials details in order to deploy your infrastructure. This varies from platform to platform; the three most used in our case are: OpenStack, Google Cloud Engine (GCE) and Amazon Web Services (AWS). For them here is what you have to pay attention to:

1. **OpenStack**: It is mandatory to download and source the RC file.
2. *GCE***: You have created and downloaded a service account file for your GCE project: _Api manager > Credentials > Create credentials > Service account key_ .
3. **AWS**: You have an IAM user along with its access key and security credentials.

Finally, here are the last steps before running the one-click-deploy-scripts:

    # Edit the file test_env_vars_for_xxx.sh  matching your cloudprovider (e.g. Openstack, Amazon, Google, Vagrant(local-deployment))
    vim test_env_vars_for_xxxx.sh

    # Inject variables into your environment
    source test_env_vars_for_xxxx.sh

    # Edit the config template config.xxx.sh-template matching your cloudprovider (e.g. Openstack, Amazon, Google, Vagrant(local-deployment))
    mv config.xxx.sh-template config.xxx.sh
    vim config.xxx.sh-template

    # Deploy (openstack)
    cloud_portal/ostack/xxxx.sh

    # Status
    cloud_portal/xxxx/state.sh

Access services:

- http://galaxy. "your prefix" .phenomenal.cloud

- http://notebook. "your prefix" .phenomenal.cloud

Destroy cluster:

    # Destroy
    cloud_portal/xxxx/destroy.sh
