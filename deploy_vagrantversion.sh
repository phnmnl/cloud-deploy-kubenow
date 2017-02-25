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
ansible-playbook -i $ansible_inventory_file --skip-tags "cloudflare" KubeNow/playbooks/install-core.yml

# wait for all pods in core stack to be ready
ansible-playbook -i $ansible_inventory_file \
                 playbooks/wait_for_all_pods_ready.yml

echo "Install Phenomenal analysis tools"

# deploy jupyter
JUPYTER_PASSWORD_HASH=$( 'bin/generate-jupyter-password-hash.sh' $jupyter_password )
ansible-playbook -i $ansible_inventory_file \
                 -e "sha1_pass_jupyter=$JUPYTER_PASSWORD_HASH" \
                 playbooks/jupyter/main.yml
                 
# deploy luigi
ansible-playbook -i $ansible_inventory_file \
                 playbooks/luigi/main.yml

# deploy galaxy
# a kubetoken is a good api-key
galaxy_api_key=$( 'KubeNow/generate_kubetoken.sh' )
ansible-playbook -i $ansible_inventory_file \
                 -e "galaxy_admin_password=$galaxy_admin_password" \
                 -e "galaxy_admin_email=$galaxy_admin_email" \
                 -e "galaxy_api_key=$galaxy_api_key" \
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
                 
  
