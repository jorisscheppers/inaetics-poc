#!/bin/bash

set -xe

curlo() {
	command curl -sSLO "$@"
}

mkdir /var/ftpd
mkdir /var/ftpd/pxelinux.cfg
mkdir /var/ftpd/memdisk
mkdir /var/ftpd/flatcar_production

#root files
cd /var/ftpd
curlo https://github.com/jorisscheppers/inaetics-poc/blob/4db59064f1efdd18a742ed522f87fc0f916af61a/PXE/ldlinux.c32
curlo https://github.com/jorisscheppers/inaetics-poc/blob/4db59064f1efdd18a742ed522f87fc0f916af61a/PXE/menu.c32
curlo https://github.com/jorisscheppers/inaetics-poc/blob/4db59064f1efdd18a742ed522f87fc0f916af61a/PXE/pxelinux.0

#pxelinux config files for each known node
cd /var/ftpd/pxelinux.cfg
curlo https://raw.githubusercontent.com/jorisscheppers/inaetics-poc/main/PXE/pxelinux.cfg/01-c0-3f-d5-64-fd-54
curlo https://raw.githubusercontent.com/jorisscheppers/inaetics-poc/main/PXE/pxelinux.cfg/01-c0-3f-d5-67-01-ab
curlo https://raw.githubusercontent.com/jorisscheppers/inaetics-poc/main/PXE/pxelinux.cfg/01-c0-3f-d5-67-02-9f

#memdisk files
cd /var/ftpd/
curl -sSL https://github.com/jorisscheppers/inaetics-poc/raw/79259e8c64cdff255bf430234ac622a9424b5ca4/PXE/memdisk.tar tar -C /var/ftpd/memdisk -xz

#flatcar linux latest stable release
cd /var/ftpd/flatcar_production
curlo https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe_image.cpio.gz
curlo https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe_grub.efi
curlo https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe.vmlinuz
curlo https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe.sh


#download and enable dnsmasq
#download dnsmasq and overwrite config
#restart dnsmasq service 
