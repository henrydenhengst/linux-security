# Podman + Hugo + PHP Contact Form Stack

Deploys:
- DuckDNS - Dynamic DNS updater
- Caddy - Auto-SSL reverse proxy
- Nginx - Static file server for Hugo
- PHP-FPM - Contact form processing with msmtp mail relay

## Security Notes
- All containers run rootless (poduser)
- SELinux enforcing
- Automatic security updates enabled
- Firewall only opens ports 80/443
- Email via DuckDuckGo forwarding (no 2FA, no SMTP credentials)

## File Structure After Deployment
```
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
## Prerequisites

On your local machine (control node):
sudo dnf install ansible   (Rocky/RHEL)

On your server:
- Rocky Linux 8 or 9
- SSH access with root or sudo privileges
- Ports 80 and 443 open in your router

## Configuration Files

### vars.yml

```
duckdns_subdomain: "denhengst"
duckdns_token: "YOUR_TOKEN_HERE"
duckdns_update_ip: "ipv4"
caddy_version: "latest"
nginx_version: "alpine"
duckdns_version: "latest"
php_version: "8.3"
timezone: "Europe/Amsterdam"
podman_user: "poduser"
container_user_uid: 1000
container_user_gid: 1000
duck_email: "vcp5693@duck.com"
domain_name: "{{ duckdns_subdomain }}.duckdns.org"
open_ports:
  - 80
  - 443
selinux_enabled: true
health_check_interval: 30s
health_check_timeout: 10s
health_check_retries: 3
```
### inventory.ini
```
[web_servers]
your-server ansible_host=192.168.1.100 ansible_user=root
```
## Deployment Commands
```
vim vars.yml
vim inventory.ini
ansible -i inventory.ini web_servers -m ping
ansible-playbook deploy-web-stack.yml --check
ansible-playbook deploy-web-stack.yml
sleep 60
ssh poduser@yourserver "podman ps"
curl https://denhengst.duckdns.org/info.php
```
## Verify Email is Working

### Step 1: Check if msmtp is installed
```
ssh poduser@yourserver "podman exec php-fpm which msmtp"
```
### Step 2: Check msmtp configuration
```
ssh poduser@yourserver "podman exec php-fpm cat /etc/msmtprc"
```
### Step 3: Manual test with msmtp
```
ssh poduser@yourserver "podman exec php-fpm sh -c 'echo -e \"Subject: Test\n\nHallo wereld\" | msmtp vcp5693@duck.com'"
```
### Step 4: Test PHP mail() function
```
ssh poduser@yourserver "podman exec php-fpm php -r \"mail('vcp5693@duck.com', 'Test from PHP', 'Your contact form works!', 'From: vcp5693@duck.com');\""
```
### Step 5: Check if sendmail binary exists
```
ssh poduser@yourserver "podman exec php-fpm ls -la /usr/sbin/sendmail"
```
### Step 6: If sendmail is missing, install msmtp-mta
```
ssh poduser@yourserver "podman exec php-fpm apk add --no-cache msmtp msmtp-mta"
```
### Step 7: Check PHP sendmail path
```
ssh poduser@yourserver "podman exec php-fpm php -i | grep sendmail"
```
### Step 8: Restart container if needed
```
ssh poduser@yourserver "podman restart php-fpm"
```
### Step 9: Check DuckDuckGo forwarding
Go to https://duckduckgo.com/email
Verify that vcp5693@duck.com is active
Verify your Gmail address is connected
Check if emails are in queue

### Step 10: Check Gmail spam folder
Emails from DuckDuckGo may go to spam. Mark them as "Not spam".

## Deploy Your Hugo Site
```
hugo -d public/
rsync -avz public/ poduser@yourserver:/home/poduser/containers/nginx/html/
```
## How Email Forwarding Works
```
User submits contact form
        ↓
PHP mail() function in container
        ↓
msmtp relays to DuckDuckGo SMTP
        ↓
DuckDuckGo receives at vcp5693@duck.com
        ↓
DuckDuckGo forwards to your Gmail inbox

No Gmail SMTP, no 2FA, no App Passwords needed!
```
## Management Commands

### Check container status:
```
ssh poduser@yourserver "podman ps"
```
### View logs:
```
ssh poduser@yourserver "podman logs php-fpm"
ssh poduser@yourserver "podman logs nginx"
ssh poduser@yourserver "podman logs caddy"
ssh poduser@yourserver "podman logs duckdns"
```
### Restart containers:
```
ssh poduser@yourserver "podman restart duckdns php-fpm nginx caddy"
```
### Complete removal (for clean redeploy):
```
ssh poduser@yourserver "podman stop duckdns php-fpm nginx caddy && podman rm duckdns php-fpm nginx caddy && podman network rm webnet"
```
## Access Web Interfaces

- Website: https://denhengst.duckdns.org
- Contact form: https://denhengst.duckdns.org/contact.html
- Cockpit UI: https://JOUW_IP:9090 (login: poduser)
- PHP info: https://denhengst.duckdns.org/info.php (remove after testing)

## Troubleshooting

### Email not arriving - complete checklist:

1. Test msmtp manually
2. Check DuckDuckGo forwarding settings
3. Check Gmail spam folder
4. Verify container can reach internet: podman exec php-fpm ping -c 4 8.8.8.8
5. Check msmtp logs: podman exec php-fpm cat /var/log/msmtp.log
6. Verify DNS resolution: podman exec php-fpm nslookup duck.com
7. Test with different email address

### Container won't start:
```
ssh poduser@yourserver "podman logs php-fpm"
```
### Website not accessible:
```
ssh root@yourserver "firewall-cmd --list-ports"
ssh poduser@yourserver "podman ps"
```
### SELinux issues:
```
ssh root@yourserver "ausearch -m avc -ts recent"
```
## Important Notes

- Remove info.php after testing - security risk
- SSL certificates auto-renew via Caddy
- DuckDNS updates your IP every 5 minutes
- Backup your vars.yml - contains your DuckDNS token
- First email may take 30-60 seconds to arrive
- Check Gmail spam folder for first emails