# Podman + Hugo + PHP Contact Form Stack

## Deploys: DuckDNS, Caddy, Nginx, PHP-FPM met msmtp

### Security Notes

- Alle containers draaien rootless (poduser)
- SELinux enforcing
- Automatische security updates
- Firewall alleen poort 80 en 443 open
- Email via DuckDuckGo forwarding (geen 2FA)

### Bestandsstructuur na deploy
```
/home/poduser/containers/
├── caddy/
│   ├── Caddyfile
│   ├── data/
│   └── config/
├── nginx/
│   ├── html/          ← Jouw Hugo site komt hier
│   └── conf.d/
└── duckdns/
└── config/
```

### Benodigdheden

Op jouw lokale machine:
```
sudo dnf install ansible   # (Rocky/RHEL)
```

### Op de server:

- Rocky Linux 8 of 9
- SSH toegang met root
- Poort 80 en 443 open in router

### Configuratiebestanden

vars.yml

```
duckdns_subdomain: "denhengst"
duckdns_token: "JOUW_TOKEN_HIER"
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

inventory.ini
```
[web_servers]
jouw-server ansible_host=192.168.1.100 ansible_user=root
```

Deployment commando's
```
vim vars.yml
vim inventory.ini
ansible -i inventory.ini web_servers -m ping
ansible-playbook deploy-web-stack.yml --check
ansible-playbook deploy-web-stack.yml
sleep 60
ssh poduser@jouwserver "podman ps"
curl https://denhengst.duckdns.org/info.php
```

Email testen

```
ssh poduser@jouwserver "podman exec php-fpm php -r \"mail('vcp5693@duck.com', 'Test', 'Werkt!');\""
```

Hugo site deployen
```
hugo -d public/
rsync -avz public/ poduser@jouwserver:/home/poduser/containers/nginx/html/
```

Management commando's

Container status:
```
ssh poduser@jouwserver "podman ps"
```

Logs bekijken:
```
ssh poduser@jouwserver "podman logs php-fpm"
ssh poduser@jouwserver "podman logs nginx"
ssh poduser@jouwserver "podman logs caddy"
ssh poduser@jouwserver "podman logs duckdns"
```

Herstarten:
```
ssh poduser@jouwserver "podman restart duckdns php-fpm nginx caddy"
```

Alles verwijderen (voor schone redeploy):
```
ssh poduser@jouwserver "podman stop duckdns php-fpm nginx caddy && podman rm duckdns php-fpm nginx caddy && podman network rm webnet"
```

Toegang
```
Website: https://denhengst.duckdns.org
Contactformulier: https://denhengst.duckdns.org/contact.html
Cockpit UI: https://JOUW_IP:9090 (login: poduser)
```

Hoe email werkt

Contactformulier ingevuld -> PHP mail() -> msmtp -> localhost:25 -> DuckDuckGo (vcp5693@duck.com) -> forwarded naar jouw Gmail

Geen Gmail SMTP, geen 2FA, geen App Passwords nodig!

Problemen oplossen

Container start niet:
```
ssh poduser@jouwserver "podman logs container-naam"
```

Email komt niet aan:
```
ssh poduser@jouwserver "podman exec php-fpm php -r \"mail('vcp5693@duck.com', 'Test', 'Hi');\""
```

Check of DuckDuckGo forwarding werkt op duckduckgo.com/email

Website niet bereikbaar:
```
ssh root@jouwserver "firewall-cmd --list-ports"
ssh poduser@jouwserver "podman ps"
```

Belangrijk

- Verwijder info.php na testen
- SSL vernieuwt automatisch via Caddy
- DuckDNS update elke 5 minuten
- Backup je vars.yml (bevat token)
