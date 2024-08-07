#!/bin/bash

# Install pm2
read -p "Install pm2? (yes/y) " INSTALL_PM2
if [[ $INSTALL_PM2 =~ ^[Yy]([Ee][Ss])?$ ]]; then
  echo "Installing pm2..."
  sudo npm install -g pm2
  echo "pm2 installed."
fi

# Install and configure Nginx
read -p "Install Nginx? (yes/y) " INSTALL_NGINX
if [[ $INSTALL_NGINX =~ ^[Yy]([Ee][Ss])?$ ]]; then
  echo "Installing Nginx..."
  sudo apt install -y nginx
  echo "Nginx installed."

  echo "Configuring Nginx..."
  # Remove Nginx version from HTTP headers
  echo "Removing Nginx version from headers..."
  sudo sed -i 's/# server_tokens off;/server_tokens off;/' /etc/nginx/nginx.conf

  # SSL/TLS configuration
  echo "Configuring SSL/TLS..."
  SSL_CONFIG="
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_prefer_server_ciphers on;
  ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
  ssl_session_timeout 1d;
  ssl_session_cache shared:SSL:10m;
  ssl_session_tickets off;
  ssl_dhparam /etc/nginx/dhparam.pem;
  "
  sudo mkdir -p /etc/nginx/conf.d
  echo "$SSL_CONFIG" | sudo tee /etc/nginx/conf.d/ssl.conf

  # Generate Diffie-Hellman parameters for stronger security
  echo "Generating Diffie-Hellman parameters..."
  sudo openssl dhparam -out /etc/nginx/dhparam.pem 2048

  # Limit request methods
  echo "Limiting request methods..."
  LIMIT_METHODS="
  if (\$request_method !~ ^(GET|POST|HEAD)$ ) {
      return 444;
  }
  "
  echo "$LIMIT_METHODS" | sudo tee /etc/nginx/conf.d/limit_methods.conf

  # Rate limiting
  echo "Configuring rate limiting..."
  RATE_LIMIT="
  limit_req_zone \$binary_remote_addr zone=mylimit:10m rate=10r/s;
  limit_conn_zone \$binary_remote_addr zone=addr:10m;
  "
  echo "$RATE_LIMIT" | sudo tee /etc/nginx/conf.d/rate_limit.conf

  # Ensure proper permissions
  echo "Setting correct file permissions..."
  sudo chown -R root:root /etc/nginx
  sudo chmod -R 755 /etc/nginx

  # Configure logging
  echo "Configuring logging..."
  LOG_CONFIG="
  log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';
  access_log /var/log/nginx/access.log main;
  error_log /var/log/nginx/error.log warn;
  "
  echo "$LOG_CONFIG" | sudo tee /etc/nginx/conf.d/logging.conf

  # Restart Nginx to apply changes
  echo "Restarting Nginx to apply changes..."
  sudo systemctl restart nginx

  echo "Nginx hardening complete."
fi

# Install Node.js
read -p "Install latest Node.js version? (yes/y) " INSTALL_NODE
if [[ $INSTALL_NODE =~ ^[Yy]([Ee][Ss])?$ ]]; then
  echo "Installing Node.js..."
  curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
  sudo apt install -y nodejs
  echo "Node.js installed."
fi

# Install Docker
read -p "Install Docker? (yes/y) " INSTALL_DOCKER
if [[ $INSTALL_DOCKER =~ ^[Yy]([Ee][Ss])?$ ]]; then
  echo "Installing Docker..."
  sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update
  sudo apt install -y docker-ce
  sudo systemctl status docker
  echo "Docker installed."
fi
