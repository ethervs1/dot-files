#!/bin/bash
set -euo pipefail

# =============================================================================
# macOS Fresh Setup Script (Sonoma or later, Apple Silicon)
# Usage: ./setup.sh [--all | --dirs | --xcode | --brew | --shell | --ssh | --mas | --vscode | --cleanup]
#        Sin argumentos muestra el menu interactivo.
#
# Cadena de dependencias (orden recomendado para fresh install):
#   1. dirs    → sin dependencias
#   2. xcode   → sin dependencias
#   3. brew    → requiere xcode, instala todo del Brewfile (formulae, casks, mas apps*, vscode extensions*)
#                *mas requiere login en App Store, *vscode requiere 'code' en PATH
#   4. shell   → requiere brew (instala oh-my-zsh, luego agrega brew shellenv a .zshrc)
#   5. ssh     → sin dependencias
#   6. mas     → DEPRECATED - ahora se instala via brew (Brewfile)
#   7. vscode  → requiere brew (VS Code instalado), requiere 'code' en PATH, lee Brewfile
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

  mkdir -p ~/vault/git ~/vault/temp ~/vault/desktop

  ln -sfn ~/vault/git ~/git
  ln -sfn ~/vault/temp ~/temp
  ln -sfn ~/vault/desktop ~/Desktop/desktop

  # mkdir -p ~/Documents/git ~/Documents/temp
  # ln -sfn ~/Documents/git ~/git
  # ln -sfn ~/Documents/temp ~/temp

  cp -r ./dot-files ~/git
  ls -la  ~/git
  ls -la  ~/temp

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
# Nota: Usa Brewfile para instalar taps, formulae, casks, mas apps, vscode extensions, etc.
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

  local brewfile="$SCRIPT_DIR/Brewfile"

  if [[ ! -f "$brewfile" ]]; then
    error "Brewfile no encontrado en: $brewfile"
    return 1
  fi

  info "Instalando paquetes desde Brewfile..."
  info "Nota: brew bundle instala taps, formulae, casks, mas apps y vscode extensions"

  # brew bundle instala todo lo del Brewfile:
  # - taps
  # - formulae
  # - casks
  # - mas (App Store apps) - requiere login previo en App Store
  # - vscode extensions - requiere 'code' en PATH
  # - npm packages
  # - uv packages
  if ! brew bundle --file="$brewfile" --no-lock; then
    warn "brew bundle reporto algunos errores. Revisa el output arriba."
    warn "Nota: es normal que fallen algunas apps de mas si no estas logueado en App Store"
    warn "Nota: es normal que fallen vscode extensions si 'code' no esta en PATH"
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
  append_once 'source ~/vault/git/dot-files/init.zsh'

  info "=== Modulo Shell completado ==="
}

# =============================================================================
# Modulo: SSH (1Password agent)
# =============================================================================
mod_1password_ssh() {
  info "=== Modulo: SSH ==="

  info "Configurando SSH para 1Password agent..."
  mkdir -p ~/.ssh
  cat > ~/.ssh/config << 'EOF'
Host *
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOF
  chmod 600 ~/.ssh/config

# Setear que vaults se pueden usar para leer las llaves SSH, si esto no esta seteado, se usaran todas los vaults para buscar las llaves privadas
  mkdir -p ~/.config/1Password/ssh
  cat > ~/.config/1Password/ssh/agent.toml << 'EOF'
# Current client
[[ssh-keys]]
vault = "Disney"

# Personal vault
[[ssh-keys]]
vault = "Development"
EOF

  info "=== Modulo SSH completado ==="
}

# =============================================================================
# Modulo: Mac App Store
# Dependencias: brew (mas), login en App Store
# Nota: Extrae las apps de mas del Brewfile y las instala via 'mas install'
# =============================================================================
mod_mas() {
  info "=== Modulo: Mac App Store ==="

  if ! command -v mas &>/dev/null; then
    error "'mas' no encontrado. Ejecuta primero el modulo Homebrew."
    return 1
  fi

  local brewfile="$SCRIPT_DIR/Brewfile"

  if [[ ! -f "$brewfile" ]]; then
    error "Brewfile no encontrado en: $brewfile"
    return 1
  fi

  info "Extrayendo apps de Mac App Store desde Brewfile..."

  # Extrae todas las lineas que empiezan con 'mas "' del Brewfile
  # Formato: mas "App Name", id: 123456
  local apps=()
  while IFS= read -r line; do
    if [[ "$line" =~ ^mas[[:space:]]+\"([^\"]+)\",[[:space:]]*id:[[:space:]]*([0-9]+) ]]; then
      local name="${BASH_REMATCH[1]}"
      local id="${BASH_REMATCH[2]}"
      apps+=("$id:$name")
    fi
  done < "$brewfile"

  if [[ ${#apps[@]} -eq 0 ]]; then
    warn "No se encontraron apps de Mac App Store en el Brewfile"
    return 0
  fi

  info "Instalando ${#apps[@]} apps de Mac App Store..."
  warn "Asegurate de estar logueado en la App Store antes de continuar."
  echo -n "Presiona Enter para continuar..."
  read -r

  local failed_mas=()
  for entry in "${apps[@]}"; do
    local id="${entry%%:*}"
    local name="${entry#*:}"
    echo "  $name (id: $id)..."
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
# Nota: Extrae las extensiones del Brewfile y las instala via 'code --install-extension'
# =============================================================================
mod_vscode() {
  info "=== Modulo: VS Code Extensions ==="

  if ! command -v code &>/dev/null; then
    error "'code' no encontrado en PATH."
    error "Abre VS Code > Cmd+Shift+P > 'Shell Command: Install code command in PATH'"
    return 1
  fi

  local brewfile="$SCRIPT_DIR/Brewfile"

  if [[ ! -f "$brewfile" ]]; then
    error "Brewfile no encontrado en: $brewfile"
    return 1
  fi

  info "Extrayendo extensiones de VS Code desde Brewfile..."

  # Extrae todas las lineas que empiezan con 'vscode "' del Brewfile
  local extensions=()
  while IFS= read -r line; do
    # Extrae el nombre de la extension entre comillas
    if [[ "$line" =~ ^vscode[[:space:]]+\"([^\"]+)\" ]]; then
      extensions+=("${BASH_REMATCH[1]}")
    fi
  done < "$brewfile"

  if [[ ${#extensions[@]} -eq 0 ]]; then
    warn "No se encontraron extensiones de VS Code en el Brewfile"
    return 0
  fi

  info "Instalando ${#extensions[@]} extensiones de VS Code..."

  local failed_ext=()
  for ext in "${extensions[@]}"; do
    echo "  $ext..."
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
  echo "  3) Homebrew + Apps          (requiere: 2, lee Brewfile)"
  echo "  4) Shell (Oh My Zsh, P10k)  (requiere: 3)"
  echo "  5) SSH (1Password agent)"
  echo "  6) Mac App Store            (requiere: 3, login en App Store, lee Brewfile)"
  echo "  7) VS Code Extensions       (requiere: 3, 'code' en PATH, lee Brewfile)"
  echo "  8) Cleanup                  (requiere: 3)"
  echo "  0) Salir"
  echo "========================================="
  echo -e "${YELLOW}Orden recomendado fresh install: 1 2 3 4 5 (6 y 7 opcionales)${NC}"
  echo -e "${YELLOW}Nota: mod_brew (3) instala casi todo via Brewfile, incluyendo mas/vscode${NC}"
  echo -n "Selecciona modulos (separados por espacio): "
  read -r choices

  for choice in $choices; do
    case $choice in
      1) mod_dirs ;;
      2) mod_xcode ;;
      3) mod_brew ;;
      4) mod_shell ;;
      5) mod_1password_ssh ;;
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
  while [[ $# -gt 0 ]]; do
    arg="$1"
    case $arg in
      --all)
        mod_dirs
        mod_xcode
        mod_brew
        mod_shell
        mod_1password_ssh
        mod_mas
        mod_vscode
        mod_cleanup
        ;;
      --dirs)     mod_dirs ;;
      --xcode)    mod_xcode ;;
      --brew)     mod_brew ;;
      --shell)    mod_shell ;;
      --ssh)      mod_1password_ssh ;;
      --mas)      mod_mas ;;
      --vscode)   mod_vscode ;;
      --cleanup)  mod_cleanup ;;
      *)          error "Argumento desconocido: $arg"; exit 1 ;;
    esac
    shift
  done
fi

echo ""
info "=== Setup finalizado ==="
info "Abre una nueva terminal (o ejecuta source ~/.zshrc) y corre: p10k configure"
