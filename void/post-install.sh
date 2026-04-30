#!/bin/sh
# post-install.sh voor Void Linux - De Sudo & Ansible methode

# 1. Update de package manager en het systeem
xbps-install -Syu xbps && xbps-install -Syu

# 2. Installeer de kern-tools
xbps-install -y vim git ansible python3 sudo podman

# 3. Configureer sudo voor de 'wheel' groep
# We zorgen dat gebruikers in de wheel groep alles mogen
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
chmod 0440 /etc/sudoers.d/wheel

# 4. Services aanzetten voor Podman en netwerk
ln -s /etc/sv/dbus /var/service/
ln -s /etc/sv/sshd /var/service/

echo "--- Klaar! Sudo is geconfigureerd en Ansible is klaar voor gebruik. ---"
