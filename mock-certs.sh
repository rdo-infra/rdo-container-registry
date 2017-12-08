#!/bin/bash

set -eux
domains="registry.rdoproject.org \
 trunk.registry.rdoproject.org \
 console.registry.rdoproject.org \
 registry.distributed-ci.io"

for bin in cfssl cfssljson; do
    [ -f ${bin} ] || curl -o ${bin} https://pkg.cfssl.org/R1.2/${bin}_linux-amd64
    chmod +x ${bin}
done

# we force RSA to please OpenShift
./cfssl print-defaults config|sed 's/^}/,"key": {"algo": "rsa", "size": 2048}}/' > ca-config.json
./cfssl print-defaults csr|sed 's/^}/,"key": {"algo": "rsa", "size": 2048}}/' > ca-csr.json

if [ ! -e /etc/pki/ca-trust/source/anchors/mocked.pem ]; then
    echo "Prepare the CA"
    ./cfssl gencert -initca ca-csr.json | ./cfssljson -bare /etc/pki/ca-trust/source/anchors/mocked -
    update-ca-trust extract
fi

for domain in ${domains}; do
    mkdir -p /etc/letsencrypt/live/${domain}
    if [ ! -e /etc/letsencrypt/live/${domain}/${domain}-privkey.pem ]; then
        ./cfssl gencert \
                -ca /etc/pki/ca-trust/source/anchors/mocked.pem \
                -ca-key /etc/pki/ca-trust/source/anchors/mocked-key.pem \
                -hostname=${domain} ca-config.json| ./cfssljson -bare /etc/letsencrypt/live/${domain}/cert
        cp /etc/letsencrypt/live/${domain}/cert.pem /etc/letsencrypt/live/${domain}/chain.pem
        cp /etc/letsencrypt/live/${domain}/cert.pem /etc/letsencrypt/live/${domain}/fullchain.pem
        cp /etc/letsencrypt/live/${domain}/cert-key.pem /etc/letsencrypt/live/${domain}/privkey.pem
        cp /etc/letsencrypt/live/${domain}/cert.pem /etc/letsencrypt/live/${domain}/${domain}-cert.pem
        cp /etc/letsencrypt/live/${domain}/cert.pem /etc/letsencrypt/live/${domain}/${domain}-chain.pem
        cp /etc/letsencrypt/live/${domain}/cert.pem /etc/letsencrypt/live/${domain}/${domain}-fullchain.pem
        cp /etc/letsencrypt/live/${domain}/cert-key.pem /etc/letsencrypt/live/${domain}/${domain}-privkey.pem
        openssl verify /etc/letsencrypt/live/${domain}/chain.pem
    fi
    find /etc/letsencrypt/live/${domain} -type f -exec chmod 644 {} \;
done
