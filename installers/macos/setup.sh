#!/bin/bash
set -euo pipefail

# =============================================================================
# macOS Fresh Setup Script (Sonoma or later, Apple Silicon)
# Usage: ./setup.sh [--profile <nombre>] [--all | --dirs | --xcode | --brew | --shell | --ssh | --mas | --vscode | --cleanup]
#        Sin argumentos muestra el menu interactivo.
#
# --profile elige que brewfile_<nombre> usar (work, personal, ...).
#   Si se omite, se pregunta de forma interactiva. Tambien sirve SETUP_PROFILE.
#   Ejemplo: ./setup.sh --profile personal --brew
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

# =============================================================================
# Preflight: la carpeta ~/dot-files tiene que existir
# mod_dirs la copia a ~/v_git, asi que sin ella el setup no sirve de nada.
# Se valida al arrancar (antes del menu y antes de procesar argumentos) para
# fallar de inmediato en vez de a mitad de la instalacion.
# =============================================================================
DOTFILES_SRC="$HOME/dot-files"

require_dotfiles() {
  if [[ ! -d "$DOTFILES_SRC" ]]; then
    error "Carpeta requerida no encontrada: $DOTFILES_SRC"
    error "Copia o clona el repo dot-files en $DOTFILES_SRC y vuelve a correr este script."
    exit 1
  fi
  info "Carpeta dot-files encontrada: $DOTFILES_SRC"
}

require_dotfiles

# --- Evitar duplicar lineas en .zshrc ---
append_once() {
  local line="$1"
  local file="${2:-$HOME/.zshrc}"
  grep -qxF "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

# =============================================================================
# Perfil de Brewfile (work / personal / ...)
# Los modulos brew, mas y vscode leen todos el MISMO Brewfile, elegido aqui.
# Se puede fijar de tres formas (en orden de precedencia):
#   1. Flag:     ./setup.sh --profile personal --brew
#   2. Env var:  SETUP_PROFILE=personal ./setup.sh --brew
#   3. Prompt interactivo (si no se especifico ninguno)
# Los perfiles disponibles se descubren solos: cada archivo brewfile_<nombre>
# en este directorio es un perfil valido.
# =============================================================================
PROFILE="${SETUP_PROFILE:-}"
BREWFILE=""

# Lista los perfiles disponibles segun los archivos brewfile_* presentes
list_profiles() {
  local f
  for f in "$SCRIPT_DIR"/brewfile_*; do
    [[ -f "$f" ]] || continue
    echo "${f##*/brewfile_}"
  done
}

# Deja el Brewfile elegido en $BREWFILE. Solo pregunta una vez por ejecucion.
resolve_brewfile() {
  [[ -n "$BREWFILE" ]] && return 0

  local available
  available="$(list_profiles)"
  if [[ -z "$available" ]]; then
    error "No se encontro ningun archivo brewfile_* en: $SCRIPT_DIR"
    return 1
  fi

  if [[ -z "$PROFILE" ]]; then
    echo ""
    info "Perfiles de Brewfile disponibles:"
    echo "$available" | sed 's/^/    - /'
    echo -n "Selecciona perfil: "
    read -r PROFILE
  fi

  local candidate="$SCRIPT_DIR/brewfile_$PROFILE"
  if [[ ! -f "$candidate" ]]; then
    error "Perfil invalido: '$PROFILE' (no existe $candidate)"
    error "Perfiles disponibles: $(echo "$available" | tr '\n' ' ')"
    PROFILE=""   # permitir reintentar si se sigue en el menu
    return 1
  fi

  BREWFILE="$candidate"
  info "Perfil de Brewfile: $PROFILE  ->  $BREWFILE"
}

# =============================================================================
# Modulo: Directorios y Symlinks
# =============================================================================
mod_dirs() {
  info "=== Modulo: Directorios y Symlinks ==="

  mkdir -p ~/vault/v_git ~/vault/v_temp ~/vault/v_desktop ~/vault/v_documents ~/vault/v_downloads

  ln -sfn ~/vault/v_desktop ~/Desktop/v_desktop
  ln -sfn ~/vault/v_git ~/v_documents
  ln -sfn ~/vault/v_git ~/v_git
  ln -sfn ~/vault/v_downloads ~/v_downloads
  ln -sfn ~/vault/v_temp ~/v_temp

  cp -r "$DOTFILES_SRC" ~/v_git
  ls -la  ~/v_git
  ls -la  ~/v_temp

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

  resolve_brewfile || return 1
  local brewfile="$BREWFILE"

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
  if ! brew bundle --file="$brewfile"; then
    warn "brew bundle reporto algunos errores. Revisa el output arriba."
    warn "Nota: es normal que fallen algunas apps de mas si no estas logueado en App Store"
    warn "Nota: es normal que fallen vscode extensions si 'code' no esta en PATH"
  fi

  info "=== Modulo Homebrew + Apps completado ==="
}

mod_work_profile() {
  info "=== Modulo: Work ==="
  # Estos paquetes no fueron instalados por homebrew, pero ahora si
  brew install --cask microsoft-teams

  info "Ms Teams instalado"
  
  # Correr todo esto como sudo
  sudo curl -Lo /usr/local/bin/devx "https://devx-cli.global.twdcgrid.net/download/macos-arm64/devx"
  sudo chmod +x /usr/local/bin/devx

  info "devx cli instalado."
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
  append_once 'source ~/vault/v_git/dot-files/dot-files/init.zsh'

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
  info "=== Debes activar el agente SSH en 1Password antes de usar git y ssh ==="
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

  resolve_brewfile || return 1
  local brewfile="$BREWFILE"

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

  resolve_brewfile || return 1
  local brewfile="$BREWFILE"

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
  echo " Si es el laptop de trabajo, logueate en globant self service primero que todo y en App Store"
  echo "  1) Directorios y Symlinks"
  echo "  2) Xcode Command Line Tools"
  echo "  3) Homebrew + Apps          (requiere: 2, lee Brewfile)"
  echo "  4) Shell (Oh My Zsh, P10k)  (requiere: 3)"
  echo "  5) SSH (1Password agent)"
  echo "  6) Mac App Store            (requiere: 3, login en App Store, lee Brewfile)"
  echo "  7) VS Code Extensions       (requiere: 3, 'code' en PATH, lee Brewfile)"
  echo "  8) Work Profile             (Instala todo lo otro antes de seguir con esto)"  
  echo "  9) Cleanup                  (requiere: 3)"
  echo "  0) Salir"
  echo "========================================="
  echo -e "${YELLOW}Nota: mod_brew (3) instala casi todo via Brewfile, incluyendo mas/vscode${NC}"
  echo -e "${YELLOW}Nota: los modulos 3, 6 y 7 preguntan el perfil de Brewfile ($(list_profiles | tr '\n' ' ')) la primera vez${NC}"
  echo -e "Nota: El iterm colors se baja asi wget -O "iterm_profiles.zip" https://github.com/mbadolato/iTerm2-Color-Schemes/zipball/master (de preferencia en ~/v_git) se hace unzip, y se usa la carpeta schemes en Iterm2"
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
      8) mod_work_profile ;;
      9) mod_cleanup ;;
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
      --profile)
        if [[ -z "${2:-}" ]]; then
          error "--profile requiere un nombre (ej: --profile personal)"
          error "Perfiles disponibles: $(list_profiles | tr '\n' ' ')"
          exit 1
        fi
        PROFILE="$2"
        BREWFILE=""   # forzar re-resolucion con el perfil nuevo
        shift
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
