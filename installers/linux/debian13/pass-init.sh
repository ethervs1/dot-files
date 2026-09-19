#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Initialize Password Store (pass) vault for user 'demo'
# Run as: bash pass-init.sh [--gpg-id ID] [--git-remote URL]
# ============================================================

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[INFO]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Parse arguments
GPG_ID=""
GIT_REMOTE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --gpg-id)
            GPG_ID="$2"
            shift 2
            ;;
        --git-remote)
            GIT_REMOTE="$2"
            shift 2
            ;;
        *)
            err "Opción desconocida: $1"
            ;;
    esac
done

echo ""
echo "============================================"
echo "  INICIALIZAR PASSWORD STORE (pass)"
echo "============================================"
echo ""

# Check if running as demo user
if [ "$(whoami)" != "demo" ]; then
    err "Este script debe ejecutarse como usuario 'demo'"
fi

# --- Step 1: Check existing GPG keys ---
echo "========== 1. VERIFICAR CLAVES GPG =========="
echo ""

mapfile -t GPG_KEYS < <(gpg --list-keys --format=colons 2>/dev/null | grep "^pub:" | cut -d: -f5)

if [ ${#GPG_KEYS[@]} -eq 0 ]; then
    err "❌ No se encontraron claves GPG. Debes generar una primero:"
    echo ""
    echo "   gpg --full-generate-key"
    echo ""
    echo "Selecciona:"
    echo "  - Tipo: RSA (default)"
    echo "  - Tamaño: 4096 bits"
    echo "  - Validez: 0 (sin expiración)"
    echo ""
fi

warn "Claves GPG disponibles:"
for i in "${!GPG_KEYS[@]}"; do
    KEY_ID="${GPG_KEYS[$i]}"
    KEY_NAME=$(gpg --list-keys "$KEY_ID" 2>/dev/null | grep uid | head -1 | sed 's/.*uid.*: //')
    echo "  [$i] $KEY_ID - $KEY_NAME"
done
echo ""

# --- Step 2: Select or use provided GPG ID ---
echo "========== 2. SELECCIONAR CLAVE GPG =========="
echo ""

if [ -n "$GPG_ID" ]; then
    # Validate provided GPG ID
    if gpg --list-keys "$GPG_ID" &>/dev/null; then
        log "Usando GPG ID proporcionado: $GPG_ID"
    else
        err "GPG ID no válido o no encontrado: $GPG_ID"
    fi
else
    # If only one key, use it automatically
    if [ ${#GPG_KEYS[@]} -eq 1 ]; then
        GPG_ID="${GPG_KEYS[0]}"
        log "Clave GPG seleccionada automáticamente: $GPG_ID"
    else
        # Multiple keys, ask user
        read -p "Selecciona el índice de la clave a usar [0]: " choice
        choice=${choice:-0}

        if [[ ! $choice =~ ^[0-9]+$ ]] || [ "$choice" -ge "${#GPG_KEYS[@]}" ]; then
            err "Selección inválida"
        fi

        GPG_ID="${GPG_KEYS[$choice]}"
        log "Clave GPG seleccionada: $GPG_ID"
    fi
fi
echo ""

# --- Step 3: Check if pass vault already exists ---
echo "========== 3. INICIALIZAR VAULT =========="
echo ""

PASS_DIR="$HOME/.password-store"

if [ -d "$PASS_DIR" ] && [ -f "$PASS_DIR/.gpg-id" ]; then
    EXISTING_ID=$(cat "$PASS_DIR/.gpg-id")
    warn "Password Store ya inicializado con: $EXISTING_ID"

    read -p "¿Reinicializar con $GPG_ID? (s/n) [n]: " reinit
    if [[ ! "$reinit" =~ ^[Ss]$ ]]; then
        warn "Abortado. Vault existente preservado."
        exit 0
    fi
fi

# Initialize pass
pass init "$GPG_ID" 2>/dev/null || true
log "Password Store inicializado: $PASS_DIR"
echo ""

# --- Step 4: Verify initialization ---
echo "========== 4. VERIFICACIÓN =========="
echo ""
pass
echo ""

# --- Step 5: Initialize git repo (optional) ---
echo "========== 5. GIT SYNC (opcional) =========="
echo ""

if [ -d "$PASS_DIR/.git" ]; then
    warn "Repositorio git ya existe en vault"
else
    read -p "¿Inicializar git en vault para versionado? (s/n) [s]: " use_git
    if [[ "$use_git" =~ ^[Ss]?$ ]]; then
        pass git init
        log "Repositorio git inicializado en vault"

        if [ -n "$GIT_REMOTE" ]; then
            pass git remote add origin "$GIT_REMOTE"
            pass git push -u origin main 2>/dev/null || \
                warn "No se pudo hacer push inicial (rama main puede no existir)"
            log "Remoto git configurado: $GIT_REMOTE"
        else
            echo ""
            echo "Para agregar repositorio remoto:"
            echo "  pass git remote add origin <git-url>"
            echo "  pass git push -u origin main"
        fi
    fi
fi
echo ""

# --- Step 6: Create recommended structure ---
echo "========== 6. CREAR ESTRUCTURA DE CARPETAS =========="
echo ""

FOLDERS=(
    "work/github"
    "work/gitlab"
    "work/api-keys"
    "infra/databases"
    "infra/servers"
    "personal/email"
    "apps"
)

for folder in "${FOLDERS[@]}"; do
    mkdir -p "$PASS_DIR/$folder"
done

log "Estructura de carpetas creada"
pass
echo ""

# --- Final summary ---
echo "============================================"
echo "  PASSWORD STORE INICIALIZADO"
echo "============================================"
echo ""
echo "  Vault        : $PASS_DIR"
echo "  GPG ID       : $GPG_ID"
echo "  Git Repo     : $([ -d "$PASS_DIR/.git" ] && echo 'Sí' || echo 'No')"
echo ""
echo "Próximos pasos:"
echo "  pass generate work/github <longitud>"
echo "  pass insert work/gitlab"
echo "  pass -c work/github  # Copiar al clipboard"
echo ""
echo "Documentación: https://www.passwordstore.org/"
echo "============================================"
echo ""
