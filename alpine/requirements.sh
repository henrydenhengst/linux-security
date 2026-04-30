#!/bin/sh

# Stop direct als er een fout optreedt
set -e

echo "--- Start installatie van Ansible, Git en Vim op Alpine ---"

# 1. Update de pakketindex
apk update

# 2. Installeer de basis tools
# We voegen py3-pip en python3 toe omdat Ansible dit nodig heeft
apk add --no-cache \
    ansible \
    git \
    vim \
    python3 \
    py3-pip \
    curl \
    openssh-client

# 3. Controleer de installaties
echo "--- Installatie voltooid. Versies: ---"
ansible --version | head -n 1
git --version
vim --version | head -n 1

echo "--- Systeem is klaar voor Ansible deployment ---"
