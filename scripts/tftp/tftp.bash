#!/bin/bash

set -xe

curl() {
	command curl -sSL "$@"
}

mkdir /var/ftpd
mkdir /var/ftpd/pxelinux.cfg
mkdir /var/ftpd/memdisk
mkdir /var/ftpd/flatcar_production

#root files
cd /var/ftpd
curl https://github.com/jorisscheppers/inaetics-poc/blob/4db59064f1efdd18a742ed522f87fc0f916af61a/PXE/ldlinux.c32
curl https://github.com/jorisscheppers/inaetics-poc/blob/4db59064f1efdd18a742ed522f87fc0f916af61a/PXE/menu.c32
curl https://github.com/jorisscheppers/inaetics-poc/blob/4db59064f1efdd18a742ed522f87fc0f916af61a/PXE/pxelinux.0

#pxelinux config files for each known node
cd /var/ftpd/pxelinux.cfg
curl https://raw.githubusercontent.com/jorisscheppers/inaetics-poc/main/PXE/pxelinux.cfg/01-c0-3f-d5-64-fd-54
curl https://raw.githubusercontent.com/jorisscheppers/inaetics-poc/main/PXE/pxelinux.cfg/01-c0-3f-d5-67-01-ab
curl https://raw.githubusercontent.com/jorisscheppers/inaetics-poc/main/PXE/pxelinux.cfg/01-c0-3f-d5-67-02-9f

#memdisk files
cd /var/ftpd/memdisk
curl https://github.com/jorisscheppers/inaetics-poc/blob/a091e27ac7637fd32420ef21741b1beb919fbc93/PXE/memdisk.zip | tar -C /var/ftpd/memdisk -xz

#flatcar linux latest stable release
cd /var/ftpd/flatcar_production
curl https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe_image.cpio.gz
curl https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe_grub.efi
curl https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe.vmlinuz
curl https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe.sh



#download and enable dnsmasq
#download dnsmasq and overwrite config
#restart dnsmasq service 
