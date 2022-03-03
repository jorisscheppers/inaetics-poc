#!/bin/bash

set -xe

DOWNLOAD_DIR=/opt/bin
export PATH=$PATH:$DOWNLOAD_DIR

curl http://infra.cluster.local/secrets/exports.bash | tee /configs/exports.bash
source /configs/exports.bash

kubectl apply -f http://infra.cluster.local/clusters/infra/informationgrid-ns.yaml

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm -n informationgrid install mongodb http://infra.cluster.local/archives/mongodb-10.28.7.tgz --values http://infra.cluster.local/clusters/infra/mongodb-values.yaml
helm -n informationgrid install kafka http://infra.cluster.local/archives/kafka-14.2.5.tgz --values http://infra.cluster.local/clusters/infra/kafka-values.yaml
helm -n informationgrid install elasticsearch http://infra.cluster.local/archives/elasticsearch-17.1.1.tgz --values http://infra.cluster.local/clusters/infra/elasticsearch-values.yaml

kubectl apply -f http://infra.cluster.local/clusters/infra/mongodb-nodeport.yaml

kubectl -n informationgrid create secret docker-registry informationgrid-pullsecret \
    --docker-server=informationgrid-docker.luminis.net \
    --docker-username=$NEXUS_USERNAME \
    --docker-password=$NEXUS_PASSWORD

kubectl apply -f http://infra.cluster.local/clusters/informationgrid-deployment.yaml
kubectl apply -f http://infra.cluster.local/clusters/ig-nodeport.yaml