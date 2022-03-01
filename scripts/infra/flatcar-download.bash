#!/bin/bash
set -xe

#recreate flatcar_production folder
sudo rm -rf /var/ftpd/flatcar_production
sudo mkdir /var/ftpd/flatcar_production

#flatcar linux latest stable release
cd /var/ftpd/flatcar_production
curlo https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe_image.cpio.g
curlo https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe_grub.efi
curlo https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe.vmlinuz
curlo https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe.sh