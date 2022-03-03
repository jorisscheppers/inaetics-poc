#!/bin/bash

docker run -d -p 5000:5000 --restart=always --name registry registry:2

REGISTRY="infra.cluster.local"

docker pull bitnami/bitnami-shell:10-debian-10-r199
docker pull bitnami/elasticsearch:7.14.2-debian-10-r1
docker pull bitnami/kafka:2.8.1-debian-10-r31
docker pull bitnami/mongodb:4.4.10-debian-10-r15
docker pull bitnami/zookeeper:3.7.0-debian-10-r188

docker tag bitnami/bitnami-shell:10-debian-10-r199 $REGISTRY/bitnami/bitnami-shell:10-debian-10-r199
docker tag bitnami/elasticsearch:7.14.2-debian-10-r1 $REGISTRY/bitnami/elasticsearch:7.14.2-debian-10-r1
docker tag bitnami/kafka:2.8.1-debian-10-r31 $REGISTRY/bitnami/kafka:2.8.1-debian-10-r31
docker tag bitnami/mongodb:4.4.10-debian-10-r15 $REGISTRY/bitnami/mongodb:4.4.10-debian-10-r15
docker tag bitnami/zookeeper:3.7.0-debian-10-r188 $REGISTRY/bitnami/zookeeper:3.7.0-debian-10-r188

docker push $REGISTRY/bitnami/bitnami-shell:10-debian-10-r199
docker push $REGISTRY/bitnami/elasticsearch:7.14.2-debian-10-r1
docker push $REGISTRY/bitnami/kafka:2.8.1-debian-10-r31
docker push $REGISTRY/bitnami/mongodb:4.4.10-debian-10-r15
docker push $REGISTRY/bitnami/zookeeper:3.7.0-debian-10-r188