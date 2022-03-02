#!/bin/bash
set -xe

#stop and remove all running containers
for container_id in $(docker ps -q); do docker stop $container_id; done
for container_id in $(docker ps -a -q); do docker rm $container_id; done

#remove shared folders
sudo rm -rf /var/ftpd/pxelinux.cfg
sudo rm -rf /share

#create ftpd dirs
sudo mkdir -p /var/ftpd

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
sudo cp /sources/inaetics-poc/configs /share/


#run Docker container for DNS and DHCP services
docker run -d -p 53:53/udp -p 67:67/udp --name dhcpdns --cap-add=NET_ADMIN --mount type=bind,source=/share/configs/dnsmasq.conf,target=/etc/dnsmasq.conf,readonly strm/dnsmasq 

#run Docker container for TFTP service
docker run -d -p 69:1069/udp --name tftp-container --env TFTPD_EXTRA_ARGS="--blocksize 1468" --mount type=bind,source=/var/ftpd/flatcar_production,target=/tftpboot/boot,readonly --mount type=bind,source=/var/ftpd/pxelinux.cfg,target=/tftpboot/pxelinux.cfg,readonly kalaksi/tftpd 

#MANUAL STEP:
# copy exports.bash to tftp server, folder /share/secrets

#run nginx container for exports file
docker run -d -p 8000:80 --name httpshare -v /share:/usr/share/nginx/html:ro nginx