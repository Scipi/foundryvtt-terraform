#!/bin/bash

if [[ ! -d /root/.acme.sh ]]; then
    echo "Downloading Let's Encrypt! code"
    mkdir /etc/pki/tls/certs/${domain}
    export HOME=/root
    curl https://get.acme.sh | sh
fi
if ! /root/.acme.sh/acme.sh --list | grep ${subdomain}.${domain}; then
    echo "Getting SSL certificate for ${subdomain}.${domain} from Let's Encrypt!"
    systemctl start httpd
    mkdir /etc/pki/tls/certs/${domain}
    /root/.acme.sh/acme.sh --set-default-ca  --server  letsencrypt
    /root/.acme.sh/acme.sh --issue -d ${subdomain}.${domain} -w /var/www/html --debug
    /root/.acme.sh/acme.sh --install-cert -d ${subdomain}.${domain} \
        --cert-file /etc/pki/tls/certs/${domain}/cert.pem \
        --key-file /etc/pki/tls/certs/${domain}/key.pem  \
        --fullchain-file /etc/pki/tls/certs/${domain}/fullchain.pem
fi
if [ -f /etc/httpd/conf.d/foundry.conf.disabled ]; then
    echo "Enable foundry http service"
    mv /etc/httpd/conf.d/foundry.conf.disabled /etc/httpd/conf.d/foundry.conf
    systemctl restart httpd
fi