#!/bin/bash

# Install necessary packages
echo "Installing necessary packages..."
sudo apt install -y vim curl ufw
echo "Installed vim, curl, and ufw - configuring ufw..."

# Configure UFW
echo "Configuring UFW..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
read -p "Do you want to allow HTTP traffic? (yes/y) " ALLOW_HTTP
if [[ $ALLOW_HTTP =~ ^[Yy]([Ee][Ss])?$ ]]; then
  sudo ufw allow http
fi
read -p "Do you want to allow HTTPS traffic? (yes/y) " ALLOW_HTTPS
if [[ $ALLOW_HTTPS =~ ^[Yy]([Ee][Ss])?$ ]]; then
  sudo ufw allow https
fi
sudo ufw enable
echo "UFW configured and enabled."

# Install and configure Fail2Ban
echo "Installing and configuring Fail2Ban..."
sudo apt install -y fail2ban

# Create a local copy of the jail configuration file
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Configure Fail2Ban for SSH
sudo tee -a /etc/fail2ban/jail.local > /dev/null <<EOL
[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
maxretry = 3
EOL

# Restart Fail2Ban service
sudo systemctl restart fail2ban
sudo systemctl enable fail2ban
echo "Fail2Ban installed and configured."

# Set up automatic security updates
echo "Configuring automatic security updates..."
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades

# Disable IPv6 if not needed
echo "Disabling IPv6..."
sudo tee -a /etc/sysctl.conf > /dev/null <<EOL
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOL
sudo sysctl -p
echo "IPv6 disabled."

echo "Basic install complete."
