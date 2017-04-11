#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

jupyter_password=""
galaxy_admin_password="password" # need to be 6 characters long
galaxy_admin_email="yourname@yourdomain.com"

ansible_inventory_file="inventory"
domain=$( grep 'domain=' $ansible_inventory_file | cut -d "=" -f 2 )
http_port=$( grep 'http_port=' $ansible_inventory_file | cut -d "=" -f 2 )

export ANSIBLE_HOST_KEY_CHECKING=False

echo "Install KubeNow core components (networking, gluster etc.)"
ansible-playbook -i $ansible_inventory_file --skip-tags "cloudflare,glusterfs" KubeNow/playbooks/install-core.yml
ansible-playbook -i $ansible_inventory_file KubeNow/playbooks/install-nfs-volume.yml

# wait for all pods in core stack to be ready
ansible-playbook -i $ansible_inventory_file \
                 playbooks/wait_for_all_pods_ready.yml


if [ "$1" = "--skip-phenomenal" ]; then
   echo "Exit before Install Phenomenal analysis tools"
   exit 0
fi

echo "Install Phenomenal analysis tools"

# deploy phenomenal-pvc
ansible-playbook -i $ansible_inventory_file \
                 playbooks/phenomenal_pvc/main.yml

# deploy jupyter
ansible-playbook -i $ansible_inventory_file \
                 -e "jupyter_chart_version=0.1.1" \
                 -e "jupyter_image_tag=:v387f29b6ca83_cv0.4.7" \
                 -e "jupyter_password=$jupyter_password" \
                 -e "jupyter_pvc=galaxy-pvc" \
                 -e "jupyter_resource_req_cpu=200m" \
                 -e "jupyter_resource_req_memory=1G" \
                 playbooks/jupyter.yml
                 
# deploy luigi
ansible-playbook -i $ansible_inventory_file \
                 playbooks/luigi/main.yml

# deploy galaxy
# a kubetoken is a good api-key
galaxy_api_key=$( 'KubeNow/generate_kubetoken.sh' )
ansible-playbook -i $ansible_inventory_file \
                 -e "galaxy_chart_version=0.1.6-phenomenal-alanine" \
                 -e "galaxy_image_tag=:v16.07-pheno_cv0.1.59" \
                 -e "galaxy_admin_password=$galaxy_admin_password" \
                 -e "galaxy_admin_email=$galaxy_admin_email" \
                 -e "galaxy_api_key=$galaxy_api_key" \
                 -e "galaxy_pvc=galaxy-pvc" \
                 -e "postgres_pvc=false" \
                 playbooks/galaxy.yml
                 
# wait until jupyter is up and do git clone data into the container
ansible-playbook -i $ansible_inventory_file \
                 playbooks/git_clone_mtbls233.yml

# wait for jupyter notebook http response != Bad Gateway
jupyter_url="http://notebook.$domain:$http_port"
ansible-playbook -i $ansible_inventory_file \
                 -e "name=jupyter-notebook" \
                 -e "url=$jupyter_url" \
                 playbooks/wait_for_http_not_down.yml
                               
# wait for luigi http response != Bad Gateway
luigi_url="http://luigi.$domain:$http_port"
ansible-playbook -i $ansible_inventory_file \
                 -e "name=luigi" \
                 -e "url=$luigi_url" \
                 playbooks/wait_for_http_not_down.yml
   
# wait for galaxy http response 200 OK
galaxy_url="http://galaxy.$domain:$http_port"
ansible-playbook -i $ansible_inventory_file \
                 -e "name=galaxy" \
                 -e "url=$galaxy_url" \
                 playbooks/wait_for_http_ok.yml


echo You should now be able to run the services at:
echo "Galaxy= $galaxy_url"
echo "Jupyter= $jupyter_url"
echo "Luigi= $luigi_url"
                 
  
