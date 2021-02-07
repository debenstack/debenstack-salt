#! /bin/bash

# Install Salt
sudo curl -L https://bootstrap.saltstack.com -o bootstrap_salt.sh
sudo sh bootstrap_salt.sh

# Copy Salt Configuration
sudo cp -f ./conf/minion /etc/salt/minion

# Copy Folders To Their Server Locations
sudo mkdir /srv/salt
sudo mkdir /srv/pillar

sudo cp -rf ./salt /srv/salt
sudo cp -rf ./pillar /srv/pillar