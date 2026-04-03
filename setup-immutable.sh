#!/usr/bin/env bash

set -euo pipefail

echo "== Immutable Linux Unified Setup =="

# --- Detect distro ---
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
else
  echo "Kan OS niet detecteren"
  exit 1
fi

DISTRO="$ID"
VARIANT="${VARIANT_ID:-unknown}"

echo "Detected: $DISTRO ($VARIANT)"

# --- Common vars ---
USER_NAME="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$USER_NAME")

FLATPAK_APPS=(
  org.mozilla.firefox
  org.libreoffice.LibreOffice
  org.videolan.VLC
  org.gimp.GIMP
  org.kde.kdenlive
  org.keepassxc.KeePassXC
  com.discordapp.Discord
  org.signal.Signal
  com.visualstudio.code
  org.chromium.Chromium
  org.remmina.Remmina
  org.filezillaproject.Filezilla
)

# --- Helpers ---
setup_flatpak() {
  echo "== Flatpak setup =="
  sudo -u "$USER_NAME" flatpak remote-add --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo || true

  for app in "${FLATPAK_APPS[@]}"; do
    sudo -u "$USER_NAME" flatpak install -y flathub "$app" || true
  done
}

setup_dirs() {
  echo "== Directories =="
  mkdir -p "$USER_HOME/Projects" \
           "$USER_HOME/Containers" \
           "$USER_HOME/Workspace"
  chown -R "$USER_NAME:$USER_NAME" "$USER_HOME"
}

# =========================
# Fedora Silverblue / Kinoite
# =========================
setup_fedora_atomic() {
  echo "== Fedora Atomic setup =="

  rpm-ostree install -y toolbox || true

  echo "Reboot mogelijk nodig na rpm-ostree install"

  sudo -u "$USER_NAME" toolbox create dev || true

  sudo -u "$USER_NAME" toolbox run sudo dnf install -y \
    git vim neovim nodejs npm python3 python3-pip \
    gcc gcc-c++ make || true

  systemctl --user enable --now podman.socket || true
}

# =========================
# openSUSE Aeon / MicroOS
# =========================
setup_opensuse_atomic() {
  echo "== openSUSE Atomic setup =="

  transactional-update pkg install -y distrobox podman git || true

  echo "Reboot vereist na transactional-update"

  sudo -u "$USER_NAME" systemctl --user enable --now podman.socket || true

  sudo -u "$USER_NAME" distrobox create \
    --name dev \
    --image registry.opensuse.org/opensuse/tumbleweed || true

  sudo -u "$USER_NAME" distrobox enter dev -- sudo zypper install -y \
    vim neovim nodejs python3 gcc make || true
}

# =========================
# NixOS
# =========================
setup_nixos() {
  echo "== NixOS setup =="

  CONFIG_PATH="/etc/nixos/configuration.nix"
  BACKUP_PATH="${CONFIG_PATH}.bak.$(date +%s)"

  if [[ -f "$CONFIG_PATH" ]]; then
    cp "$CONFIG_PATH" "$BACKUP_PATH"
    echo "Backup: $BACKUP_PATH"
  fi

  cat > "$CONFIG_PATH" << 'EOF'
{ config, pkgs, ... }:

{
  system.stateVersion = "24.11";

  networking.hostName = "nixos-desktop";

  users.users.user = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "podman" ];
  };

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.flatpak.enable = true;

  virtualisation.podman.enable = true;

  environment.systemPackages = with pkgs; [
    git vim neovim wget curl
    firefox libreoffice vlc gimp
    keepassxc filezilla remmina
    distrobox podman
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
EOF

  echo "Validatie..."
  nixos-rebuild test

  echo "Toepassen..."
  nixos-rebuild switch
}

# =========================
# Dispatcher
# =========================
case "$DISTRO" in
  fedora)
    setup_flatpak
    setup_fedora_atomic
    ;;

  opensuse*|opensuse-tumbleweed|opensuse-microos)
    setup_flatpak
    setup_opensuse_atomic
    ;;

  nixos)
    setup_nixos
    setup_flatpak
    ;;

  *)
    echo "Niet ondersteunde distro: $DISTRO"
    exit 1
    ;;
esac

setup_dirs

echo "== Setup voltooid =="

echo ""
echo "Post-install stappen:"
echo "1. Reboot aanbevolen"
echo "2. Test containers:"
echo "   distrobox enter dev / toolbox enter dev"
echo "3. Controle:"
echo "   flatpak list"
echo "   podman info"
echo ""