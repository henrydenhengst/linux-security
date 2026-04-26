# Podman + Hugo + PHP Contact Form Stack

Deploys:
- **DuckDNS** - Dynamic DNS updater
- **Caddy** - Auto-SSL reverse proxy
- **Nginx** - Static file server for Hugo
- **PHP-FPM** - Contact form processing

## Security Notes
- All containers run rootless (poduser)
- SELinux enforcing
- Automatic security updates enabled
- Firewall only opens ports 80/443

## File Structure After Deployment

```text
/home/poduser/containers/
├── caddy/
│   ├── Caddyfile
│   ├── data/
│   └── config/
├── nginx/
│   ├── html/          ← Put your Hugo site here
│   └── conf.d/
└── duckdns/
    └── config/
```


```bash

# 0. PREREQUISITES
#   Rocky/RHEL: sudo dnf install ansible

# 1. Edit vars.yml with your DuckDNS token and subdomain
vim vars.yml

# 1.5 Verify your vars.yml has all required variables:
#   duckdns_subdomain: "your-subdomain"
#   duckdns_token: "your-token"
#   contact_email: "your-email@example.com"  # For PHP contact form
#   timezone: "America/New_York"
#   podman_user: "poduser"

# 2. Update inventory.ini with your server IP
vim inventory.ini

# 3. Test connection to your server
ansible -i inventory.ini web_servers -m ping

# 4. Run the playbook in check mode (dry run)
ansible-playbook deploy-web-stack.yml --check

# 4.5 AFTER deployment - test PHP is working:
curl https://your-subdomain.duckdns.org/info.php
# (Remove info.php after testing for security)

# 5. Run the playbook for real
ansible-playbook deploy-web-stack.yml

# 5.5 Check container status manually:
ssh poduser@yourserver "podman ps"

# 6. If you want to see detailed output
ansible-playbook deploy-web-stack.yml -vv

# 7. To run on localhost instead of remote server
echo "[web_servers]" > inventory_local.ini
echo "localhost ansible_connection=local" >> inventory_local.ini
ansible-playbook -i inventory_local.ini deploy-web-stack.yml

# 8. Build your Hugo site locally
hugo -d public/

# 8.5 For automatic Hugo deploys (optional - add git hook):
# On your server, in /home/poduser/containers/nginx/html/
git init --bare && cat > hooks/post-receive << 'EOF'
#!/bin/bash
git --work-tree=/home/poduser/containers/nginx/html --git-dir=.git checkout -f
EOF
chmod +x hooks/post-receive

# 9. Copy to server (static content)
rsync -avz public/ poduser@yourserver:/home/poduser/containers/nginx/html/

# 10. PHP scripts (contact form) live in same directory
# They work automatically alongside your static Hugo site

# 11. View contact form submissions (emails go to your contact_email)
# No special command - emails arrive in your inbox!

# 12. Troubleshooting - Check container logs if something fails:
ssh poduser@yourserver "podman logs php-fpm"
ssh poduser@yourserver "podman logs nginx"
ssh poduser@yourserver "podman logs caddy"
ssh poduser@yourserver "podman logs duckdns"
```