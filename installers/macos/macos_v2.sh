#!/bin/bash
set -euo pipefail

# =============================================================================
# macOS Fresh Setup Script (Sonoma or later, Apple Silicon)
# Usage: ./macos_v2.sh [--all | --dirs | --xcode | --brew | --shell | --ssh | --mas | --vscode | --cleanup]
#        Sin argumentos muestra el menu interactivo.
#
# Cadena de dependencias (orden recomendado para fresh install):
#   1. dirs    → sin dependencias
#   2. xcode   → sin dependencias
#   3. brew    → requiere xcode
#   4. shell   → requiere brew (instala oh-my-zsh, luego agrega brew shellenv a .zshrc)
#   5. ssh     → sin dependencias
#   6. mas     → requiere brew (mas), requiere login en App Store
#   7. vscode  → requiere brew (VS Code instalado), requiere 'code' en PATH
#   8. cleanup → requiere brew, requiere mole instalado
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname -- "$0")" && pwd)"

# --- Colores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[-]${NC} $1"; }

# --- Evitar duplicar lineas en .zshrc ---
append_once() {
  local line="$1"
  local file="${2:-$HOME/.zshrc}"
  grep -qxF "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

# =============================================================================
# Modulo: Directorios y Symlinks
# =============================================================================
mod_dirs() {
  info "=== Modulo: Directorios y Symlinks ==="

  mkdir -p ~/Documents/git ~/Documents/temp
  ln -sfn ~/Documents/git ~/git
  ln -sfn ~/Documents/temp ~/temp

  info "=== Modulo Directorios completado ==="
}

# =============================================================================
# Modulo: Xcode Command Line Tools
# =============================================================================
mod_xcode() {
  info "=== Modulo: Xcode CLT ==="

  if ! xcode-select -p &>/dev/null; then
    info "Instalando Xcode Command Line Tools..."
    xcode-select --install
    echo "Presiona cualquier tecla cuando la instalacion GUI haya terminado."
    read -r -n 1
  fi
  info "Xcode CLT instalado en: $(xcode-select -p)"

  info "=== Modulo Xcode CLT completado ==="
}

# =============================================================================
# Modulo: Homebrew + Formulae + Casks
# Dependencias: xcode
# =============================================================================
mod_brew() {
  info "=== Modulo: Homebrew + Apps ==="

  if ! command -v brew &>/dev/null; then
    info "Instalando Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    info "Homebrew ya instalado."
  fi

  # Taps
  info "Agregando taps..."
  brew tap oven-sh/bun
  brew tap productdevbook/tap
  brew tap supabase/tap

  # Formulae
  info "Instalando formulae..."
  local failed_formulae=()
  local formulae=(
    btop
    cask
    eza
    ffmpeg
    node
    gemini-cli
    gh
    git
    go-task
    hashcat
    hf
    htop
    httpie
    jq
    libpq
    lsd
    lsusb
    macchina
    mariadb
    mas
    minikube
    mole
    mongosh
    neo4j
    nmap
    nushell
    ollama
    opentofu
    pandoc
    podman
    ruby
    ruff
    subliminal
    swig
    tealdeer
    telnet
    tree
    trufflehog
    unar
    uv
    wget
    wimlib
    yt-dlp
    oven-sh/bun/bun
    supabase/tap/supabase
  )

  for pkg in "${formulae[@]}"; do
    if ! output=$(brew install "$pkg" 2>&1); then
      failed_formulae+=("$pkg: $(echo "$output" | tail -1)")
    fi
  done

  if [[ ${#failed_formulae[@]} -gt 0 ]]; then
    warn "Formulae que fallaron:"
    for f in "${failed_formulae[@]}"; do
      warn "  - $f"
    done
  fi

  # Casks
  info "Instalando casks..."
  local failed_casks=()
  local casks=(
    1password
    1password-cli
    alfred
    android-platform-tools
    claude-code
    firefox
    flutter
    google-chrome
    iterm2
    itsycal
    mactex
    nordvpn
    productdevbook/tap/portkiller
    spotify
    utm
    visual-studio-code
    vlc
    void
    webtorrent
    zoom
  )

  for pkg in "${casks[@]}"; do
    if ! output=$(brew install --cask "$pkg" 2>&1); then
      failed_casks+=("$pkg: $(echo "$output" | tail -1)")
    fi
  done

  if [[ ${#failed_casks[@]} -gt 0 ]]; then
    warn "Casks que fallaron:"
    for f in "${failed_casks[@]}"; do
      warn "  - $f"
    done
  fi

  info "=== Modulo Homebrew + Apps completado ==="
}

# =============================================================================
# Modulo: Shell (Oh My Zsh, Powerlevel10k, plugins, brew shellenv, custom init)
# Dependencias: brew
# Nota: Oh My Zsh se instala primero porque sobreescribe .zshrc.
#       Despues se agregan las lineas de brew shellenv, plugins y custom init.
# =============================================================================
mod_shell() {
  info "=== Modulo: Shell ==="

  # Oh My Zsh (primero, porque sobreescribe .zshrc)
  if [[ ! -d ~/.oh-my-zsh ]]; then
    info "Instalando Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    info "Oh My Zsh ya instalado."
  fi

  # brew shellenv (despues de oh-my-zsh para que no se pierda)
  append_once 'eval "$(/opt/homebrew/bin/brew shellenv)"'

  # Powerlevel10k
  info "Instalando Powerlevel10k..."
  brew install powerlevel10k
  append_once 'source $HOMEBREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme'

  # zsh-autocomplete
  info "Instalando zsh-autocomplete..."
  brew install zsh-autocomplete
  append_once 'source $HOMEBREW_PREFIX/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh'

  # zsh-autosuggestions
  info "Instalando zsh-autosuggestions..."
  brew install zsh-autosuggestions
  append_once 'source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh'

  # Custom init
  info "Agregando custom init a .zshrc..."
  append_once 'source ~/dot-files/init.zsh'

  info "=== Modulo Shell completado ==="
}

# =============================================================================
# Modulo: SSH (1Password agent)
# =============================================================================
mod_ssh() {
  info "=== Modulo: SSH ==="

  info "Configurando SSH para 1Password agent..."
  mkdir -p ~/.ssh
  cat > ~/.ssh/config << 'EOF'
Host *
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOF
  chmod 600 ~/.ssh/config

  info "=== Modulo SSH completado ==="
}

# =============================================================================
# Modulo: Mac App Store
# Dependencias: brew (mas), login en App Store
# =============================================================================
mod_mas() {
  info "=== Modulo: Mac App Store ==="

  if ! command -v mas &>/dev/null; then
    error "'mas' no encontrado. Ejecuta primero el modulo Homebrew."
    return 1
  fi

  local failed_mas=()
  local apps=(
    "425264550:Blackmagic Disk Speed Test"
    "540348655:Monosnap"
    "409201541:Pages"
    "425424353:The Unarchiver"
  )

  for entry in "${apps[@]}"; do
    local id="${entry%%:*}"
    local name="${entry#*:}"
    if ! output=$(mas install "$id" 2>&1); then
      failed_mas+=("$name ($id): $(echo "$output" | tail -1)")
    fi
  done

  if [[ ${#failed_mas[@]} -gt 0 ]]; then
    warn "Apps de Mac App Store que fallaron:"
    for f in "${failed_mas[@]}"; do
      warn "  - $f"
    done
  fi

  info "=== Modulo Mac App Store completado ==="
}

# =============================================================================
# Modulo: VS Code Extensions
# Dependencias: brew (VS Code), 'code' en PATH
# =============================================================================
mod_vscode() {
  info "=== Modulo: VS Code Extensions ==="

  if ! command -v code &>/dev/null; then
    error "'code' no encontrado en PATH."
    error "Abre VS Code > Cmd+Shift+P > 'Shell Command: Install code command in PATH'"
    return 1
  fi

  local failed_ext=()
  local extensions=(
    adpyke.vscode-sql-formatter
    akashrajkn.language-netlogo-code
    anthropic.claude-code
    beardedbear.beardedicons
    beardedbear.beardedtheme
    bisnetoinc.theme-excel
    blackblackcat.silver-gray
    breberaf.snowflake
    docker.docker
    dreamcatcher45.podmanager
    george-alisson.html-preview-vscode
    google.geminicodeassist
    grapecity.gc-excelviewer
    hashicorp.terraform
    huacat.pink-theme
    mechatroner.rainbow-csv
    ms-azuretools.vscode-containers
    ms-azuretools.vscode-docker
    ms-python.debugpy
    ms-python.python
    ms-python.vscode-pylance
    ms-python.vscode-python-envs
    ms-toolsai.jupyter
    ms-toolsai.jupyter-hub
    ms-toolsai.jupyter-keymap
    ms-toolsai.jupyter-renderers
    ms-toolsai.vscode-jupyter-cell-tags
    ms-toolsai.vscode-jupyter-slideshow
    ms-vscode-remote.remote-containers
    shd101wyy.markdown-preview-enhanced
    tomoki1207.pdf
    vue.volar
  )

  for ext in "${extensions[@]}"; do
    if ! output=$(code --install-extension "$ext" 2>&1); then
      failed_ext+=("$ext: $(echo "$output" | tail -1)")
    fi
  done

  if [[ ${#failed_ext[@]} -gt 0 ]]; then
    warn "Extensiones que fallaron:"
    for f in "${failed_ext[@]}"; do
      warn "  - $f"
    done
  fi

  info "=== Modulo VS Code Extensions completado ==="
}

# =============================================================================
# Modulo: Cleanup
# Dependencias: brew, mole
# =============================================================================
mod_cleanup() {
  info "=== Modulo: Cleanup ==="

  info "Ejecutando mantenimiento de Homebrew..."
  brew update && brew upgrade && brew cleanup && brew autoremove
  brew doctor || warn "brew doctor reporto advertencias (esto es normal)"

  if command -v mo &>/dev/null; then
    info "Ejecutando limpieza de mole..."
    mo clean
    mo optimize
  else
    warn "'mo' no encontrado, saltando limpieza de mole."
  fi

  info "=== Modulo Cleanup completado ==="
}

# =============================================================================
# Menu interactivo
# =============================================================================
show_menu() {
  echo ""
  echo "========================================="
  echo "  macOS Fresh Setup"
  echo "========================================="
  echo "  1) Directorios y Symlinks"
  echo "  2) Xcode Command Line Tools"
  echo "  3) Homebrew + Apps          (requiere: 2)"
  echo "  4) Shell (Oh My Zsh, P10k)  (requiere: 3)"
  echo "  5) SSH (1Password agent)"
  echo "  6) Mac App Store            (requiere: 3, login en App Store)"
  echo "  7) VS Code Extensions       (requiere: 3, 'code' en PATH { Abre VS Code > Cmd+Shift+P > 'Shell Command: Install code command in PATH' })"
  echo "  8) Cleanup                  (requiere: 3)"
  echo "  0) Salir"
  echo "========================================="
  echo -e "${YELLOW}Orden recomendado fresh install: 1 2 3 4 5 6 7 8${NC}"
  echo -n "Selecciona modulos (separados por espacio): "
  read -r choices

  for choice in $choices; do
    case $choice in
      1) mod_dirs ;;
      2) mod_xcode ;;
      3) mod_brew ;;
      4) mod_shell ;;
      5) mod_ssh ;;
      6) mod_mas ;;
      7) mod_vscode ;;
      8) mod_cleanup ;;
      0) exit 0 ;;
      *) error "Opcion invalida: $choice" ;;
    esac
  done
}

# =============================================================================
# Main
# =============================================================================
if [[ $# -eq 0 ]]; then
  show_menu
else
  for arg in "$@"; do
    case $arg in
      --all)
        mod_dirs
        mod_xcode
        mod_brew
        mod_shell
        mod_ssh
        mod_mas
        mod_vscode
        mod_cleanup
        ;;
      --dirs)     mod_dirs ;;
      --xcode)    mod_xcode ;;
      --brew)     mod_brew ;;
      --shell)    mod_shell ;;
      --ssh)      mod_ssh ;;
      --mas)      mod_mas ;;
      --vscode)   mod_vscode ;;
      --cleanup)  mod_cleanup ;;
      *)          error "Argumento desconocido: $arg"; exit 1 ;;
    esac
  done
fi

echo ""
info "=== Setup finalizado ==="
info "Abre una nueva terminal (o ejecuta source ~/.zshrc) y corre: p10k configure"
