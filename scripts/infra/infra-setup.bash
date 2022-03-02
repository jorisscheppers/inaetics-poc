#!/bin/bash
set -xe

#create sources dir and clone Git repo for all scripts
sudo rm -rf /sources
sudo mkdir /sources
cd /sources
sudo git clone https://github.com/jorisscheppers/inaetics-poc.git

sudo cp /sources/inaetics-poc/scripts/infra/services.bash /sources
sudo chmod +x /sources/services.bash