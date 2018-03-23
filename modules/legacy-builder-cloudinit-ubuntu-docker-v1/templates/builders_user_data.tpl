#!/bin/bash

set -exu

curl -o ./provision-builder.sh https://s3.amazonaws.com/circleci-enterprise/provision-builder-lxc-2016-12-05.sh
curl -o ./init-builder.sh https://s3.amazonaws.com/circleci-enterprise/init-builder-0.2.sh
bash ./provision-builder.sh
SERVICES_PRIVATE_IP='${services_private_ip}' CIRCLE_SECRET_PASSPHRASE='${circle_secret_passphrase}' bash ./init-builder.sh
