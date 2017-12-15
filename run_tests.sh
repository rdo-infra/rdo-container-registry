#!/bin/bash
set -eux

export RDO_GITHUB_CLIENT_ID=oauth_client_id
export RDO_GITHUB_CLIENT_SECRET=oauth_client_secret

function cleanup() {
    # This is used so that openshift-ansible is not in CWD when initializing
    # tox which makes it take forever to bootstrap the virtualenv
    rm -rf openshift-ansible
}

function get_user_token() {
    local user=$1

    secret_name=$(oc describe sa ${user}|awk '/Tokens:/ {print $2}')
    secret_value=$(oc describe secret ${secret_name}|awk '/token:/ {print $2}')

    echo ${secret_value}
}

function teardown() {
    sudo docker pull fedora
    sudo docker tag docker.io/fedora trunk.registry.rdoproject.org/master/fedora
    sudo docker tag docker.io/fedora registry.distributed-ci.io/rhosp12/fedora
    sudo docker logout trunk.registry.rdoproject.org
    sudo docker logout registry.distributed-ci.io
}

# Generate the local SSL certificates
sudo ./mock-certs.sh

# This runs on localhost but uses registry.rdoproject.org resources
for host in registry.rdoproject.org console.registry.rdoproject.org trunk.registry.rdoproject.org registry.distributed-ci.io
do
    if ! grep -q "127.0.0.1 ${host}" /etc/hosts; then
        echo "127.0.0.1 ${host}" | sudo tee -a /etc/hosts
    fi
done

# We'll be connecting on localhost over ssh, setup keypair authentication
if [ ! -f ~/.ssh/id_rsa.pub ]; then
    ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
fi
if ! grep -q "$(cat ~/.ssh/id_rsa.pub)" ~/.ssh/authorized_keys; then
    cat ~/.ssh/id_rsa.pub >>~/.ssh/authorized_keys
fi
ssh-keyscan -H registry.rdoproject.org >>~/.ssh/known_hosts

cleanup
tox -e ansible-playbook -- -b -i hosts host-preparation.yml -e "ansible_ssh_user=${USER}"
cleanup
# https://github.com/openshift/openshift-ansible/issues/5812
# Glean configures "NM_CONTROLLED=no" in the ifcfg-eth0 file
tox -e ansible-playbook -- -b -i hosts openshift-ansible/playbooks/byo/openshift-node/network_manager.yml -e "ansible_ssh_user=${USER}"
cleanup
tox -e ansible-playbook -- -b -i hosts openshift-ansible/playbooks/byo/config.yml -e "ansible_ssh_user=${USER}"
cleanup
tox -e ansible-playbook -- -b -i hosts projects-creation.yml -e "ansible_ssh_user=${USER}" -M openshift-ansible/roles/lib_openshift/library

sudo oc get pods
sudo oc get routes
sudo oc get svc
sudo oc get projects
sudo oc policy who-can resource cluster-admin
sudo oc get serviceaccounts --all-namespaces=true

teardown
echo "Try to push an image in master without being auth"
sudo docker push trunk.registry.rdoproject.org/master/fedora 2>&1|grep 'unauthorized: authentication required'

teardown
echo "Try to push an image in master with the proper auth"
sudo docker login -u tripleo.service -p $(get_user_token tripleo.service) trunk.registry.rdoproject.org
sudo docker push trunk.registry.rdoproject.org/master/fedora

teardown
echo "Try to pull the freshly uploaded image"
sudo docker rmi trunk.registry.rdoproject.org/master/fedora

teardown
echo "Try to push to OSP/DCI without being auth"
sudo docker push registry.distributed-ci.io/rhosp12/fedora 2>&1|grep 'unauthorized: authentication required'

teardown
echo "Try to push from OSP/DCI with the read-only account"
sudo docker login -u dci-registry-user-osp12.service -p $(get_user_token dci-registry-user-osp12.service) registry.distributed-ci.io
sudo docker push registry.distributed-ci.io/rhosp12/fedora 2>&1|grep 'unauthorized: authentication required'

teardown
echo "Try to push to OSP/DCI with the proper auth"
sudo docker login -u dci-registry-admin.service -p $(get_user_token dci-registry-admin.service) registry.distributed-ci.io
sudo docker push registry.distributed-ci.io/rhosp12/fedora

teardown
echo "Try to pull from OSP/DCI with the read-only account"
sudo docker rmi registry.distributed-ci.io/rhosp12/fedora
sudo docker login -u dci-registry-user-osp12.service -p $(get_user_token dci-registry-user-osp12.service) registry.distributed-ci.io
sudo docker pull registry.distributed-ci.io/rhosp12/fedora

teardown
echo "Try to pull from OSP/DCI without being auth"
sudo docker pull registry.distributed-ci.io/rhosp12/fedora 2>&1|grep 'unauthorized: authentication required'

echo "**** LOOKS GREAT!!! ****"
