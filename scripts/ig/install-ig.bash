#!/bin/bash

set -xe

DOWNLOAD_DIR=/opt/bin
export PATH=$PATH:$DOWNLOAD_DIR

curl http://infra.cluster.local/secrets/exports.bash | tee /configs/exports.bash

source /configs/exports.bash

flux bootstrap github --owner jorisscheppers --repository=inaetics-poc --branch=main --path=clusters/infra --personal



kubectl -n informationgrid create secret docker-registry informationgrid-pullsecret \
    --docker-server=informationgrid-docker.luminis.net \
    --docker-username=$NEXUS_USERNAME \
    --docker-password=$NEXUS_PASSWORD

kubectl apply -f /configs/informationgrid-deployment.yaml
kubectl apply -f /configs/ig-nodeport.yaml