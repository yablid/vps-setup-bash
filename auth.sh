#!/bin/bash

read -p "Name of ssh key in ~/.ssh for root user (or return for default id_rsa): " ROOT_SSH_KEY
read -p "Name of ssh key in ~/.ssh for new user (return for default id_rsa): " USER_SSH_KEY
read -p "Enter host IP: " HOST_IP

# Update and upgrade packages
echo "Updating package lists and upgrading installed packages..."
sudo apt update
sudo apt upgrade -y
echo "Updated and upgraded packages."

# Create a new superuser
read -p "Create a new sudo user with username: " NEW_USER
sudo adduser $NEW_USER

# Add new user to sudo group
sudo usermod -aG sudo $NEW_USER

# create dir if it doesnt exist and set permissions
sudo mkdir -p /home/$NEW_USER/.ssh/

# Prompt the user to copy the SSH public key
echo "Copy the SSH public key from your local machine to the new user's .ssh directory on the remote."
echo "  scp -i ~/.ssh/$ROOT_SSH_KEY ~/.ssh/$USER_SSH_KEY.pub root@$HOST_IP:/home/$NEW_USER/.ssh"

# Wait for user confirmation
while true; do
  read -p "Have you copied the SSH key? (yes/y) " RESPONSE
  case $RESPONSE in
    [yY][eE][sS]|[yY])
      break
      ;;
    *)
      echo "Please copy the SSH key before proceeding."
      ;;
  esac
done

echo "Adding key to authorized_keys for user $NEW_USER..."
sudo cat /home/$NEW_USER/.ssh/$USER_SSH_KEY.pub >> /home/$NEW_USER/.ssh/authorized_keys
sudo rm /home/$NEW_USER/.ssh/$USER_SSH_KEY.pub

echo "Setting permissions..."
# Set the correct permissions for authorized_keys
sudo chmod 700 /home/p2/.ssh
sudo chown $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh
sudo chmod 600 /home/$NEW_USER/.ssh/authorized_keys
sudo chown $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh/authorized_keys

echo "Restarting ssh service..."
# Restart the SSH service to apply changes
sudo systemctl restart ssh

# Manual connection test
ssh_works() {
  while true; do
    echo "Open a new terminal and try to SSH into the server with the new user."
    echo "  ssh -i ~/.ssh/$USER_SSH_KEY $NEW_USER@$HOST_IP"
    read -p "Can you connect? (yes/y) " RESPONSE
    case $RESPONSE in
      [yY][eE][sS]|[yY])
        break
        ;;
      *)
        echo "Please confirm you successfully connected via SSH."
        ;;
    esac
  done
}
ssh_works

# Backup SSH configuration files
echo "Backing up SSH configuration files and hardening..."
sudo cp /etc/ssh/ssh_config /etc/ssh/ssh_config.bak
sudo cp /etc/ssh/ssh_config /etc/ssh/ssh_config.bak

sudo mkdir -p /run/sshd
sudo chmod 0755 /run/sshd

#!/bin/bash

# Apply SSH client configuration hardening
echo "Applying SSH client (outbound) configuration hardening..."

echo "Setting StrictHostKeyChecking to ask for increased security when connecting to new hosts."
sudo sed -i 's/^#StrictHostKeyChecking.*/StrictHostKeyChecking ask/' /etc/ssh/ssh_config

echo "Disabling GSSAPIAuthentication."
sudo sed -i 's/^#GSSAPIAuthentication.*/GSSAPIAuthentication no/' /etc/ssh/ssh_config

echo "Disabling HostbasedAuthentication."
sudo sed -i 's/^#HostbasedAuthentication.*/HostbasedAuthentication no/' /etc/ssh/ssh_config

echo "Disabling PermitUserEnv to prevent passing environment variables to the server."
sudo sed -i 's/^#PermitUserEnv.*/PermitUserEnv no/' /etc/ssh/ssh_config

echo "Disabling DebianBanner to hide version information."
sudo sed -i 's/^#DebianBanner.*/DebianBanner no/' /etc/ssh/ssh_config

echo "Disabling Tunnel to prevent initiating of tunnel devices."
sudo sed -i 's/^#Tunnel.*/Tunnel no/' /etc/ssh/ssh_config

echo "Disabling PermitTunnel to explicitly prevent SSH tunnel device forwarding."
sudo sed -i 's/^#PermitTunnel.*/PermitTunnel no/' /etc/ssh/ssh_config

echo "Disabling AllowTcpForwarding to prevent TCP forwarding."
sudo sed -i 's/^#AllowTcpForwarding.*/AllowTcpForwarding no/' /etc/ssh/ssh_config

echo "Disabling AllowAgentForwarding to prevent SSH agent forwarding."
sudo sed -i 's/^#AllowAgentForwarding.*/AllowAgentForwarding no/' /etc/ssh/ssh_config

echo "Disabling KerberosAuthentication."
sudo sed -i 's/^#KerberosAuthentication.*/KerberosAuthentication no/' /etc/ssh/ssh_config

echo "Disabling X11Forwarding to prevent forwarding of X11 (graphical) sessions."
sudo sed -i 's/^#X11Forwarding.*/X11Forwarding no/' /etc/ssh/ssh_config

echo "Disabling Banner to remove SSH login banner."
sudo sed -i 's/^#Banner.*/Banner none/' /etc/ssh/ssh_config

echo "Commenting out existing Ciphers configuration."
sudo sed -i '/^Ciphers/s/^/#/g' /etc/ssh/ssh_config

echo "Setting strong ciphers for secure SSH communication."
echo "Ciphers aes256-ctr,aes192-ctr,aes128-ctr" | sudo tee -a /etc/ssh/ssh_config

# Apply SSH server configuration hardening
echo "Applying SSH server configuration (inbound) hardening..."

echo "Setting MaxAuthTries to 3 to limit authentication attempts."
sudo sed -i 's/^#MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config

echo "Setting LoginGraceTime to 2 minutes for login attempts."
sudo sed -i 's/^#LoginGraceTime.*/LoginGraceTime 2m/' /etc/ssh/sshd_config

echo "Disabling PermitRootLogin to prevent root login via SSH."
sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

echo "Disabling PermitEmptyPasswords to prevent login with empty passwords."
sudo sed -i 's/^#PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config

echo "Disabling PasswordAuthentication to enforce key-based authentication."
sudo sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

echo "Disabling KerberosAuthentication."
sudo sed -i 's/^#KerberosAuthentication.*/KerberosAuthentication no/' /etc/ssh/sshd_config

echo "Disabling X11Forwarding to prevent forwarding of X11 (graphical) sessions."
sudo sed -i 's/^#X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config

echo "Disabling Tunnel to prevent initiating of tunnel devices."
sudo sed -i 's/^#Tunnel.*/Tunnel no/' /etc/ssh/sshd_config

echo "Disabling PermitTunnel to explicitly prevent SSH tunnel device forwarding."
sudo sed -i 's/^#PermitTunnel.*/PermitTunnel no/' /etc/ssh/sshd_config

echo "Disabling AllowTcpForwarding to prevent TCP forwarding."
sudo sed -i 's/^#AllowTcpForwarding.*/AllowTcpForwarding no/' /etc/ssh/sshd_config

echo "Disabling AllowAgentForwarding to prevent SSH agent forwarding."
sudo sed -i 's/^#AllowAgentForwarding.*/AllowAgentForwarding no/' /etc/ssh/sshd_config

echo "Disabling GSSAPIAuthentication."
sudo sed -i 's/^#GSSAPIAuthentication.*/GSSAPIAuthentication no/' /etc/ssh/sshd_config

echo "Disabling HostbasedAuthentication."
sudo sed -i 's/^#HostbasedAuthentication.*/HostbasedAuthentication no/' /etc/ssh/sshd_config

echo "Setting StrictHostKeyChecking to ask for increased security when connecting to new hosts."
sudo sed -i 's/^#StrictHostKeyChecking.*/StrictHostKeyChecking ask/' /etc/ssh/sshd_config

echo "Disabling DebianBanner to hide version information."
sudo sed -i 's/^#DebianBanner.*/DebianBanner no/' /etc/ssh/sshd_config

echo "Disabling Banner to remove SSH login banner."
sudo sed -i 's/^#Banner.*/Banner none/' /etc/ssh/sshd_config

verify_ssh_client_config() {
  if ! ssh -G localhost >/dev/null; then
    echo "SSH client configuration syntax error. Restoring backup configuration files..."
    sudo cp /etc/ssh/ssh_config.bak /etc/ssh/ssh_config
    sudo systemctl restart ssh
    echo "Backup client configuration restored."
    exit 1
  else
    echo "SSH client configuration syntax is correct."
  fi
}
verify_ssh_client_config

verify_ssh_server_config() {
  if ! sudo sshd -t; then
    echo "SSH server configuration syntax error. Restoring backup configuration files..."
    sudo cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
    sudo systemctl restart ssh
    echo "Backup server configuration restored."
    exit 1
  else
    echo "SSH server configuration syntax is correct."
  fi
}
verify_ssh_server_config

test_ssh_connection() {
  sudo systemctl restart ssh
  while true; do
    echo "Try to SSH into the server with the new user to verify connection:"
    echo "  ssh -i ~/.ssh/$USER_SSH_KEY $NEW_USER@$HOST_IP"
    read -p "Can you still connect? (yes/y) " RESPONSE
    case $RESPONSE in
      [yY][eE][sS]|[yY])
        echo "SSH configuration hardening successful."
        break
        ;;
      *)
        echo "SSH connection failed. Restoring backup configuration files..."
        sudo cp /etc/ssh/ssh_config.bak /etc/ssh/ssh_config
        sudo cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
        sudo systemctl restart ssh
        echo "Backup configuration restored."
        exit 1
        ;;
    esac
  done
}
test_ssh_connection

echo "SSH configuration hardening successful. All done."

# Display guidance for updating local .ssh/config
echo "Optionally, n your local ~/.ssh/config, add a configuration:"
echo ""
echo "Host your_server_alias"
echo "    HostName $HOST_IP"
echo "    User $NEW_USER"
echo "    IdentityFile ~/.ssh/$USER_SSH_KEY"
echo ""

