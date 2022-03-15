#!/bin/bash
set -xe

#remove shared folders
sudo rm -rf /var/ftpd/pxelinux.cfg
sudo rm -rf /share/*


#create http shared dir
sudo mkdir -p /share
sudo mkdir -p /share/secrets

#(re)create configs folder

#copy relevant sources to destination dirs
#pxelinux config files for each known node
sudo cp -r /sources/inaetics-poc/PXE/pxelinux.cfg /var/ftpd/
#ignition configs for each known node
sudo cp -r /sources/inaetics-poc/ignition-configs /share
#all scripts
sudo cp -r /sources/inaetics-poc/scripts /share
#dnsmasq.conf
sudo cp -r /sources/inaetics-poc/configs /share
#copy cluster info to /share
sudo cp -r /sources/inaetics-poc/clusters /share
#copy archives to /share
sudo cp -r /sources/inaetics-poc/archives /share
#copy exports
sudo cp /sources/exports.bash /share/secrets

#stop and remove all running containers
for container_id in $(docker ps -q); do docker stop $container_id; done
for container_id in $(docker ps -a -q); do docker rm $container_id; done

#run Docker container for DNS and DHCP services
docker run -d --net=host --name=dhcpdns --restart=always --cap-add=NET_ADMIN --mount type=bind,source=/share/configs/dnsmasq.conf,target=/etc/dnsmasq.conf,readonly strm/dnsmasq 

#run Docker container for TFTP service
docker run -d -p 69:1069/udp --name tftp-container --restart=always --env TFTPD_EXTRA_ARGS="--blocksize 1468" --mount type=bind,source=/var/ftpd/flatcar_production,target=/tftpboot/boot,readonly --mount type=bind,source=/var/ftpd/pxelinux.cfg,target=/tftpboot/pxelinux.cfg,readonly kalaksi/tftpd 

#MANUAL STEP:
# copy exports.bash to tftp server, folder /share/secrets

#run nginx container for exports file
docker run -d -p 80:80 --name httpshare --restart=always -v /share:/usr/share/nginx/html:ro nginx

#run local docker registry for IG infra images
docker run -d -p 5000:5000 --restart=always --name registry registry:2

REGISTRY="infra.cluster.local:5000"

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


docker build -t infra.cluster.local:5000/k3sworkload:1 -f k3s-workload.dockerfile /sources/inaetics-poc/docker-images/
docker push infra.cluster.local:5000/k3sworkload:1