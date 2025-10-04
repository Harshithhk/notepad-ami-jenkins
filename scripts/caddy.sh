#!/bin/bash

echo "**************************************************************************"
echo "*                                                                        *"
echo "*                                                                        *"
echo "*                           Installing Caddy                             *"
echo "*                                                                        *"
echo "*                                                                        *"
echo "**************************************************************************"

# Step 1: Install and run Caddy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy

sudo cp ~/Caddyfile /etc/caddy/Caddyfile

sudo systemctl daemon-reload
sudo systemctl enable caddy
sudo systemctl start caddy
