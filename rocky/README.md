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
# 1. Edit vars.yml with your DuckDNS token and subdomain
vim vars.yml

# 2. Update inventory.ini with your server IP
vim inventory.ini

# 3. Test connection to your server
ansible -i inventory.ini web_servers -m ping

# 4. Run the playbook in check mode (dry run)
ansible-playbook deploy-web-stack.yml --check

# 5. Run the playbook for real
ansible-playbook deploy-web-stack.yml

# 6. If you want to see detailed output
ansible-playbook deploy-web-stack.yml -vv

# 7. To run on localhost instead of remote server
echo "[web_servers]" > inventory_local.ini
echo "localhost ansible_connection=local" >> inventory_local.ini
ansible-playbook -i inventory_local.ini deploy-web-stack.yml

# 8. Build your Hugo site locally
hugo -d public/

# 9. Copy to server (static content)
rsync -avz public/ poduser@yourserver:/home/poduser/containers/nginx/html/

# 10. PHP scripts (contact form) live in same directory
# They work automatically alongside your static Hugo site




```