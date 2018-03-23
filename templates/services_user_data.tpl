#!/bin/bash

set -exu
REPLICATED_VERSION="2.10.3"

export http_proxy="${http_proxy}"
export https_proxy="${https_proxy}"
export no_proxy="${no_proxy}"

echo "-------------------------------------------"
echo "     Performing System Updates"
echo "-------------------------------------------"
apt-get update && apt-get -y upgrade

echo "--------------------------------------------"
echo "       Setting Private IP"
echo "--------------------------------------------"
export PRIVATE_IP="$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"

echo "--------------------------------------------"
echo "          Download Replicated"
echo "--------------------------------------------"
curl -sSk -o /tmp/get_replicated.sh "https://get.replicated.com/docker?replicated_tag=$REPLICATED_VERSION&replicated_ui_tag=$REPLICATED_VERSION&replicated_operator_tag=$REPLICATED_VERSION"

echo "--------------------------------------"
echo "        Installing Docker"
echo "--------------------------------------"
apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual
apt-get install -y apt-transport-https ca-certificates curl
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get -y install docker-ce=17.03.2~ce-0~ubuntu-trusty cgmanager

# Replicated Airgap/Automated Install

cat > /etc/settings.conf <<EOF
{ "hostname": { "value": "${circle_hostname}" },
  "allow_cluster": { "value": "1" },
  "secret_passphrase": { "value": "${circle_secret_passphrase}" },
  "ghe_type": { "value": "github_type_public" },
  "ghe_client_id": { "value": "${github_id}" },
  "ghe_client_secret": { "value": "${github_secret}" },
  "storage_backend": { "value": "storage_backend_s3" },
  "aws_region": { "value": "${aws_region}" },
  "s3_bucket": { "value": "${s3_bucket}" },
  "sqs_queue_url": { "value": "${sqs_queue_url}" },
  "license_agreement": { "value": "license_agreement_agree" } }
EOF

cat > /etc/replicated.conf <<EOF
{ "DaemonAuthenticationType": "password",
  "DaemonAuthenticationPassword": "${console_password}",
  "TlsBootstrapType": "self-signed",
  "TlsBootstrapHostname": "${circle_hostname}",
  "LogLevel": "debug",
  "Channel": "stable",
  "LicenseFileLocation": "/etc/license.rli",
  "LicenseBootstrapAirgapPackagePath": "/etc/circle.airgap",
  "ImportSettingsFrom": "/etc/settings.conf",
  "BypassPreflightChecks": true }
EOF

echo "${circle_license}" | base64 --decode > /etc/license.rli

# TODO /data/circle/circleci-encryption-keys/crypt-keyset
# TODO /data/circle/circleci-encryption-keys/sign-keyset

mkdir -p /etc/circleconfig/api-service
cat > /etc/circleconfig/api-service/customizations <<EOF
# Hostname tweaks to fix workflows
EOF

curl -o /etc/circle.airgap "https://s3.amazonaws.com/circle-airgap-test/archive-2.5.0.tgz"
curl -o replicated.tgz "https://s3.amazonaws.com/replicated-airgap-work/replicated.tar.gz"
tar xzvf replicated.tgz
cat ./install.sh | sudo bash -s airgap local-address="$PRIVATE_IP" no-docker no-proxy # or http-proxy=http://...

