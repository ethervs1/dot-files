#!/bin/bash

# Enable SSH for login remotely
# sudo systemctl enable ssh
# sudo systemctl start ssh
# sudo systemctl status ssh

set -euo pipefail

# =============================================================================
# Kali Linux Unified Setup Script
# Usage: ./setup.sh [--all | --base | --offensive | --nvidia | --rtl8812au | --gemini]
#        Sin argumentos muestra el menu interactivo.
# =============================================================================

NEEDS_REBOOT=false

# --- Colores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[-]${NC} $1"; }

# --- Root check ---
require_root() {
  if [[ $EUID -ne 0 ]]; then
    error "Este script debe ejecutarse como root (sudo ./setup.sh)"
    exit 1
  fi
}

# --- Evitar duplicar lineas en .zshrc ---
append_once() {
  local line="$1"
  local file="${2:-$HOME/.zshrc}"
  grep -qxF "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

# =============================================================================
# Modulo: Base (sistema, herramientas dev, shell, SSH)
# =============================================================================
mod_base_1() {
  info "=== Modulo: Base ==="

  # Directorios y symlinks
  info "Creando directorios y symlinks..."
  mkdir -p ~/Documents/git ~/Documents/temp
  ln -sfn ~/Documents/git ~/git
  ln -sfn ~/Documents/temp ~/temp

  # Actualizar sistema
  info "Actualizando sistema..."
  sudo apt update && sudo apt upgrade -y
  NEEDS_REBOOT=true
}

mod_base_2() {
  # Dependencias base
  info "Instalando dependencias base..."
  sudo apt install -y \
    build-essential \
    vim \
    curl \
    git \
    bc \
    gnupg \
    linux-headers-"$(uname -r)" \
    software-properties-common

  # Herramientas CLI
  info "Instalando herramientas CLI..."
  sudo apt install -y \
    btop \
    ffmpeg \
    htop \
    httpie \
    jq \
    libpq-dev \
    lsd \
    mariadb-server \
    nmap \
    pandoc \
    podman \
    ruby \
    swig \
    telnet \
    tree \
    unar \
    usbutils \
    wget \
    wimtools \
    yt-dlp

  # GitHub CLI
  if ! command -v gh &>/dev/null; then
    info "Instalando GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
      sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
      sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update && sudo apt install -y gh
  fi

  # Node.js (NodeSource)
  if ! command -v node &>/dev/null; then
    info "Instalando Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
  fi

  # Bun
  if ! command -v bun &>/dev/null; then
    info "Instalando Bun..."
    curl -fsSL https://bun.sh/install | bash
  fi

  # uv
  if ! command -v uv &>/dev/null; then
    info "Instalando uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi

  # Ruff
  if ! command -v ruff &>/dev/null; then
    info "Instalando Ruff..."
    curl -LsSf https://astral.sh/ruff/install.sh | sh
  fi

  # tealdeer
  if ! command -v tldr &>/dev/null; then
    info "Instalando tealdeer..."
    sudo apt install -y tealdeer || {
      warn "tealdeer no disponible en apt, instalando via cargo..."
      cargo install tealdeer
    }
  fi

  # go-task
  if ! command -v task &>/dev/null; then
    info "Instalando go-task..."
    sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin
  fi

  # OpenTofu
  if ! command -v tofu &>/dev/null; then
    info "Instalando OpenTofu..."
    curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o /tmp/install-opentofu.sh
    chmod +x /tmp/install-opentofu.sh
    /tmp/install-opentofu.sh --install-method deb
    rm -f /tmp/install-opentofu.sh
  fi

  # TruffleHog
  if ! command -v trufflehog &>/dev/null; then
    info "Instalando TruffleHog..."
    curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin
  fi

  # mongosh
  if ! command -v mongosh &>/dev/null; then
    info "Instalando mongosh..."
    curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
      sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg
    echo "deb [signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" | \
      sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list > /dev/null
    sudo apt update && sudo apt install -y mongodb-mongosh
  fi

  # Oh My Zsh
  if [[ ! -d ~/.oh-my-zsh ]]; then
    info "Instalando Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    info "Oh My Zsh ya instalado."
  fi

  ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

  # zsh-autocomplete
  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autocomplete" ]]; then
    info "Instalando zsh-autocomplete..."
    git clone --depth=1 https://github.com/marlonrichert/zsh-autocomplete.git "$ZSH_CUSTOM/plugins/zsh-autocomplete"
  fi
  append_once 'source ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh'

  # zsh-autosuggestions
  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    info "Instalando zsh-autosuggestions..."
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  fi
  append_once 'source ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh'

  # Limpieza
  info "Limpiando paquetes innecesarios..."
  sudo apt autoremove -y && sudo apt autoclean -y

  info "=== Modulo Base completado ==="
}

# =============================================================================
# Modulo: Offensive (WiFi, Bluetooth, cracking)
# =============================================================================
mod_offensive() {
  info "=== Modulo: Offensive ==="

  info "Instalando herramientas Wi-Fi..."
  sudo apt install -y \
    aircrack-ng \
    bettercap \
    bully \
    hcxdumptool \
    hcxtools \
    iw \
    macchanger \
    reaver

  info "Instalando herramientas Bluetooth..."
  sudo apt install -y \
    bluez \
    bluez-tools \
    bluetooth \
    ubertooth

  info "Instalando herramientas de cracking..."
  sudo apt install -y \
    hashcat \
    hashcat-utils \
    john \
    wordlists \
    sqlmap

  info "Descomprimiendo rockyou.txt..."
  if [[ -f /usr/share/wordlists/rockyou.txt.gz ]]; then
    sudo gunzip -f /usr/share/wordlists/rockyou.txt.gz
  fi

  info "Habilitando servicio Bluetooth..."
  sudo systemctl enable bluetooth
  sudo systemctl start bluetooth

  info "=== Modulo Offensive completado ==="
}

# =============================================================================
# Modulo: NVIDIA RTX 3050
# =============================================================================
mod_nvidia() {
  info "=== Modulo: NVIDIA RTX 3050 ==="

  # Habilitar non-free solo en las lineas deb correctas
  info "Habilitando repositorios non-free..."
  sudo sed -i '/^deb / s/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list

  info "Actualizando repositorios..."
  sudo apt update

  info "Instalando headers del kernel..."
  sudo apt install -y linux-headers-"$(uname -r)"

  info "Blacklisteando nouveau..."
  echo -e "blacklist nouveau\noptions nouveau modeset=0" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
  sudo update-initramfs -u

  info "Instalando driver NVIDIA..."
  sudo apt install -y nvidia-driver nvidia-settings nvidia-smi

  NEEDS_REBOOT=true
  info "=== Modulo NVIDIA completado ==="
}

# =============================================================================
# Modulo: RTL8812AU (AWUS036ACH)
# =============================================================================
mod_rtl8812au() {
  info "=== Modulo: Driver RTL8812AU - AWUS036ACH ==="

  info "Eliminando drivers DKMS antiguos..."
  sudo apt purge -y realtek-rtl88xxau-dkms realtek-rtl8814au-dkms rtl8812au-dkms 2>/dev/null || true

  info "Eliminando restos DKMS..."
  dkms status | grep -qE "88..au" && sudo dkms remove -m realtek-rtl88xxau --all 2>/dev/null || true
  dkms status | grep -qE "8814au" && sudo dkms remove -m realtek-rtl8814au --all 2>/dev/null || true

  info "Instalando dependencias..."
  sudo apt install -y dkms git build-essential linux-headers-"$(uname -r)"

  info "Descargando driver (aircrack-ng)..."
  sudo rm -rf /usr/src/rtl8812au
  sudo git clone https://github.com/morrownr/8812au-20210820 /usr/src/rtl8812au

  info "Instalando driver con DKMS..."
  cd /usr/src/rtl8812au
  sudo ./install-driver.sh
  (cd /usr/src/rtl8812au && sudo make dkms_install)

  info "Cargando modulo rtl8812au..."
  sudo modprobe rtl8812au

  info "Comprobaciones:"
  lsmod | grep 8812 || warn "Modulo no cargado"
  iw dev || warn "No se detectaron interfaces WiFi"
  lsusb | grep -i alfa || warn "No se detecto adaptador ALFA por USB"

  NEEDS_REBOOT=true
  info "=== Modulo RTL8812AU completado ==="
}

# =============================================================================
# Menu interactivo
# =============================================================================
show_menu() {
  echo ""
  echo "========================================="
  echo "  Kali Linux Unified Setup"
  echo "========================================="
  echo "  1) Base (sistema, dev tools, shell) ESTA OPCION REINICIARA TU SISTEMA"
  echo "  2) Base 2 (Se debe ejecutar despues de reiniciar el sistema)"
  echo "  3) Offensive (WiFi, BT, cracking)"
  echo "  4) NVIDIA RTX 3050"
  echo "  5) RTL8812AU (AWUS036ACH)"
  echo "  6) Gemini CLI"
  echo "  0) Salir"
  echo "========================================="
  echo -n "Selecciona modulos (separados por espacio, ej: 1 2 5): "
  read -r choices

  for choice in $choices; do
    case $choice in
      1) mod_base_1 ;;
      2) mod_base_2 ;;
      3) mod_offensive ;;
      4) mod_nvidia ;;
      5) mod_rtl8812au ;;
      0) exit 0 ;;
      *) error "Opcion invalida: $choice" ;;
    esac
  done
}

# =============================================================================
# Main
# =============================================================================
require_root

if [[ $# -eq 0 ]]; then
  show_menu
else
  for arg in "$@"; do
    case $arg in
      --base1)       mod_base_1 ;;
      --base2)       mod_base_2 ;;
      --offensive)  mod_offensive ;;
      --nvidia)     mod_nvidia ;;
      --rtl8812au)  mod_rtl8812au ;;
      *)            error "Argumento desconocido: $arg"; exit 1 ;;
    esac
  done
fi

echo ""
info "=== Setup finalizado ==="

if $NEEDS_REBOOT; then
  warn "REINICIA el sistema para aplicar cambios de drivers."
fi
