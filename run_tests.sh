#!/bin/bash
set -eu

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
    sudo docker tag docker.io/fedora trunk.registry.rdoproject.org/master/fedora
    sudo docker tag docker.io/fedora registry.distributed-ci.io/rhosp12/fedora
    sudo docker logout trunk.registry.rdoproject.org
    sudo docker logout registry.distributed-ci.io
}

function ok() {
    local command=$1

    set +e
    echo "-> Should succeed: ... ${command}"
    sudo $command
    ret=$?

    if [ $ret -eq 0 ]; then
        echo "  -> OK"
    else
        echo "  -> KO"
        exit 1
    fi
    set -e
}

function ko() {
    local command=$1

    set +e
    echo "-> Should fail: ... ${command}"
    sudo $command
    ret=$?

    if [ $ret -eq 0 ]; then
        echo "  -> OK"
        exit 1
    else
        echo "  -> KO"
    fi
    set -e
}

# Install required packages
sudo yum install -y openssl

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
tox -e ansible-playbook -- -b -i hosts openshift-ansible/playbooks/deploy_cluster.yml -e "ansible_ssh_user=${USER}"
cleanup
tox -e ansible-playbook -- -b -i hosts projects-creation.yml -e "ansible_ssh_user=${USER}" -M openshift-ansible/roles/lib_openshift/library

sudo oc get pods
sudo oc get routes
sudo oc get svc
sudo oc get projects
sudo oc policy who-can resource cluster-admin
sudo oc get serviceaccounts --all-namespaces=true

sudo docker pull fedora
teardown
echo "Try to push an image in master without being auth"
ko "docker push trunk.registry.rdoproject.org/master/fedora"

teardown
echo "Try to push an image in master with the proper auth"
ok "docker login -u tripleo.service -p $(get_user_token tripleo.service) trunk.registry.rdoproject.org"
ok "docker push trunk.registry.rdoproject.org/master/fedora"

teardown
echo "Try to pull the freshly uploaded image"
ok "docker rmi trunk.registry.rdoproject.org/master/fedora"
ok "docker pull trunk.registry.rdoproject.org/master/fedora"

teardown
echo "Try to push to OSP/DCI without being auth"
ko "docker push registry.distributed-ci.io/rhosp12/fedora"

teardown
echo "Try to push from OSP/DCI with the read-only account"
ok "docker login -u dci-registry-user-osp12.service -p $(get_user_token dci-registry-user-osp12.service) registry.distributed-ci.io"
ko "docker push registry.distributed-ci.io/rhosp12/fedora"

teardown
echo "Try to push to OSP/DCI with the proper auth"
ok "docker login -u dci-registry-admin.service -p $(get_user_token dci-registry-admin.service) registry.distributed-ci.io"
ok "docker push registry.distributed-ci.io/rhosp12/fedora"

teardown
echo "Try to pull from OSP/DCI with the read-only account"
ok "docker rmi registry.distributed-ci.io/rhosp12/fedora"
ok "docker login -u dci-registry-user-osp12.service -p $(get_user_token dci-registry-user-osp12.service) registry.distributed-ci.io"
ok "docker pull registry.distributed-ci.io/rhosp12/fedora"

teardown
echo "Try to pull from OSP/DCI without being auth"
ko "docker pull registry.distributed-ci.io/rhosp12/fedora"

echo "\o/ LOOKS GREAT!!! \o/"
