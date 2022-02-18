#!/bin/bash

docker rm -f $(docker ps -a -q)

sudo rm -r /var/ftpd

set -xe

curlo() {
	command curl -sSLO "$@"
}

mkdir /var/ftpd
mkdir /var/ftpd/pxelinux.cfg
mkdir /var/ftpd/flatcar_production

mkdir /share

#pxelinux config files for each known node
cd /var/ftpd/pxelinux.cfg
curlo https://raw.githubusercontent.com/jorisscheppers/inaetics-poc/main/PXE/pxelinux.cfg/01-c0-3f-d5-64-fd-54
curlo https://raw.githubusercontent.com/jorisscheppers/inaetics-poc/main/PXE/pxelinux.cfg/01-c0-3f-d5-67-01-ab
curlo https://raw.githubusercontent.com/jorisscheppers/inaetics-poc/main/PXE/pxelinux.cfg/01-c0-3f-d5-67-02-9f

#flatcar linux latest stable release
cd /var/ftpd/flatcar_production
curlo https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe_image.cpio.gz
curlo https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe_grub.efi
curlo https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe.vmlinuz
curlo https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe.sh

#run Docker container for TFTP service
docker run -d -p 69:1069/udp --name tftp-container --env TFTPD_EXTRA_ARGS="--blocksize 1468" --mount type=bind,source=/var/ftpd/flatcar_production,target=/tftpboot/boot --mount type=bind,source=/var/ftpd/pxelinux.cfg,target=/tftpboot/pxelinux.cfg kalaksi/tftpd 

#MANUAL STEP:
# copy exports.bash to tftp server, folder /share

#run nginx container for exports file
docker run -p8000:80 --name httpshare -v /share:/usr/share/nginx/html:ro -d nginx

#run Unifi local controller
#TODO save configs (and secrets in export.bash) to USB flashdrive to keep data after a reinstall
docker run -d \
  --name=unifi-controller \
  -e PUID=1000 \
  -e PGID=1000 \
  -e MEM_LIMIT=1024 \
  -e MEM_STARTUP=1024 \
  -p 3478:3478/udp \
  -p 10001:10001/udp \
  -p 8080:8080 \
  -p 8443:8443 \
  -p 1900:1900/udp `#optional` \
  -p 5514:5514/udp `#optional` \
  -v /unifi:/config \
  --restart unless-stopped \
  lscr.io/linuxserver/unifi-controller