
# Bash scripts for initial server setup on Ubuntu (i.e. VPS)
- auth.sh (setup ssh access for new user)
- basic.sh (installs vim, curl, and ufw and configures ufw)
- webserver.sh (pm2, nginx, node, docker)

Connect to remote, for example:

```$ ssh -i /path/to/key user@ip_address``` _or_
```$ ssh user@ip_address```

Install git if you need to:

```sudo apt install -y git```

On remote, copy scripts and cd into directory:

```git clone https://github.com/yablid/vps-setup-bash.git```

```cd vps-setup-bash```

Make executable and run:
```chmod +x auth.sh basic.sh webserver.```

```./auth.sh```





