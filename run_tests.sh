#!/bin/bash
set -e
export RDO_GITHUB_CLIENT_ID=oauth_client_id
export RDO_GITHUB_CLIENT_SECRET=oauth_client_secret

echo
echo
ls -al
echo
echo

sudo pip install pip --upgrade
sudo pip install tox --upgrade

function cleanup() {
    # This is used so that openshift-ansible is not in CWD when initializing
    # tox which makes it take forever to bootstrap the virtualenv
    rm -rf openshift-ansible
}

# This runs on localhost but uses registry.rdoproject.org resources
for host in registry.rdoproject.org console.registry.rdoproject.org trunk.registry.rdoproject.org
do
    if ! grep -q "127.0.0.1 ${host}" /etc/hosts; then
        echo "127.0.0.1 ${host}" | sudo tee -a /etc/hosts
    fi
done

# We'll be connecting on localhost over ssh, setup keypair authentication
if [ ! -f ~/.ssh/id_rsa.pub ]; then
    ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
    cat ~/.ssh/id_rsa.pub >>~/.ssh/authorized_keys
    ssh-keyscan -H ${DOMAIN} >>~/.ssh/known_hosts
fi

echo
echo
ls -al
echo
echo

cleanup
tox --debug -e ansible-playbook -- -b -i hosts host-preparation.yml -e "ansible_ssh_user=${USER}"
cleanup
tox --debug -e ansible-playbook -- -b -i hosts openshift-ansible/playbooks/byo/config.yml -e "ansible_ssh_user=${USER}"

echo
echo
ls -al
echo
echo

sudo oc get pods
sudo oc get routes
sudo oc get svc
