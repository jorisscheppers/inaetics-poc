#!/bin/bash
set -xe

#remove shared folders
sudo rm -rf /var/ftpd/pxelinux.cfg
sudo rm -rf /share/


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