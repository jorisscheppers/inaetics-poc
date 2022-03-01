#!/bin/bash
set -xe

#stop and remove all running containers
docker rm -f $(docker ps -a -q)

#remove shared folders
sudo rm -r /var/ftpd
sudo rm -f /share

#set curlo command
curlo() {
	command curl -sSLO "$@"
}

#create ftpd dirs
sudo mkdir /var/ftpd
sudo mkdir /var/ftpd/pxelinux.cfg
sudo mkdir /var/ftpd/flatcar_production

#create http shared dir
sudo mkdir /share
sudo mkdir /share/secrets
sudo mkdir /share/ignition-configs
sudo mkdir /share/scripts

#flatcar linux latest stable release
cd /var/ftpd/flatcar_production
curlo https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe_image.cpio.gz
curlo https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe_grub.efi
curlo https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe.vmlinuz
curlo https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe.sh

#copy relevant sources to destination dirs
#pxelinux config files for each known node
sudo cp -r /sources/inaetics-poc/PXE/pxelinux.cfg /var/ftpd/pxelinux.cfg
#ignition configs for each known node
sudo cp -r /sources/inaetics-poc/ignition-configs /share/ignition-configs
#all scripts
sudo cp -r /sources/inaetics-poc/scripts /share/scripts

#run Docker container for TFTP service
docker run -d -p 69:1069/udp --name tftp-container --env TFTPD_EXTRA_ARGS="--blocksize 1468" --mount type=bind,source=/var/ftpd/flatcar_production,target=/tftpboot/boot --mount type=bind,source=/var/ftpd/pxelinux.cfg,target=/tftpboot/pxelinux.cfg kalaksi/tftpd 

#MANUAL STEP:
# copy exports.bash to tftp server, folder /share/secrets

#run nginx container for exports file
docker run -p8000:80 --name httpshare -v /share:/usr/share/nginx/html:ro -d nginx