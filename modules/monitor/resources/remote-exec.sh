#!/bin/bash

# Set CADDY_DOMAIN from first argument or default to example.com
CADDY_DOMAIN="${1:-example.com}"

# Function to update package lists
function update_packages() {
    echo "=== Update packages ==="
    sudo apt update
}

# Function to set up the repository and keys needed to install Caddy
function setup_caddy_repo() {
    echo "=== Set Caddy for installation ==="
    sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor --yes -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
    sudo chmod o+r /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    sudo chmod o+r /etc/apt/sources.list.d/caddy-stable.list
}

# Function to install Caddy and necessary packages
function install_caddy() {
    echo "=== Install Caddy ==="
    sudo apt update
    sudo apt install -y caddy unzip
}

# Function to move the Caddyfile to the correct location and configure it
function configure_caddyfile() {
    echo "=== Move Caddyfile to the correct location and configure it ==="
    sudo mv /tmp/Caddyfile /etc/caddy/Caddyfile
    sudo sed -i "s|CADDY_DOMAIN|${CADDY_DOMAIN}|g" /etc/caddy/Caddyfile
    sudo chown caddy:caddy /etc/caddy/Caddyfile
}

# Function to start and enable the Caddy service
function start_caddy_service() {
    echo "=== Start and enable Caddy service ==="
    sudo systemctl enable caddy
    sudo systemctl restart caddy
}

# Main function to orchestrate the script execution
function main() {
    update_packages
    setup_caddy_repo
    install_caddy
    configure_caddyfile
    start_caddy_service
}

# Execute the main function
main
