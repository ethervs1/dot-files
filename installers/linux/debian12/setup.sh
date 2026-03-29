
#!/usr/bin/env bash
set -euo pipefail
clear

# --- Validar argumento: clave pública SSH ---
if [ -z "${1:-}" ]; then
    echo -e "\033[0;31m[ERROR]\033[0m Uso: $0 <clave_publica_ssh>"
    echo -e "\033[0;31m[ERROR]\033[0m Ejemplo: $0 'ssh-ed25519 AAAA... usuario@host'"
    exit 1
fi
SSH_PUBKEY="$1"

# ============================================================
# Setup completo para Debian 12 (Bookworm) - Servidor limpio
# Ejecutar como root: bash setup-debian12-clean.sh
# Idempotente: se puede ejecutar múltiples veces sin romper nada
# Apps principales: Podman + Caddy
# ============================================================

export DEBIAN_FRONTEND=noninteractive

# --- Colores para output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[INFO]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; }

# --- Generar contraseñas seguras ---
USER_PASS=$(openssl rand -base64 16 | tr -d '/+=' | head -c 20)

echo ""
echo "============================================"
echo "  CONFIGURACION SERVIDOR DEBIAN 12"
echo "============================================"
echo ""

# ============================================================
# 1. ACTUALIZACION DEL SISTEMA
# ============================================================
echo ""
echo "========== 1. ACTUALIZACION DEL SISTEMA =========="

# --- Asegurar DNS funcional ---
if ! getent hosts deb.debian.org &>/dev/null; then
    warn "DNS no resuelve, configurando nameservers publicos"
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf
    log "DNS configurado (8.8.8.8, 1.1.1.1)"
fi

# --- Corregir mirror obsoleto (cdn.debian.net -> deb.debian.org) ---
# Debian 12 puede usar formato DEB822 (.sources) o tradicional (.list)
if [ -f /etc/apt/sources.list ]; then
    if grep -q "cdn.debian.net" /etc/apt/sources.list 2>/dev/null; then
        sed -i 's|cdn.debian.net|deb.debian.org|g' /etc/apt/sources.list
        log "Mirror corregido en sources.list: cdn.debian.net -> deb.debian.org"
    fi
fi
for f in /etc/apt/sources.list.d/*.sources /etc/apt/sources.list.d/*.list; do
    if [ -f "$f" ] && grep -q "cdn.debian.net" "$f" 2>/dev/null; then
        sed -i 's|cdn.debian.net|deb.debian.org|g' "$f"
        log "Mirror corregido en $(basename "$f"): cdn.debian.net -> deb.debian.org"
    fi
done

# --- Preconfigurar grub-pc para evitar fallo en modo noninteractive ---
# Detectar el disco de boot y configurar grub antes del upgrade
if dpkg -l grub-pc 2>/dev/null | grep -q '^ii'; then
    BOOT_DISK=$(lsblk -ndo PKNAME "$(findmnt -no SOURCE /)" 2>/dev/null || true)
    if [ -n "$BOOT_DISK" ] && [ -b "/dev/$BOOT_DISK" ]; then
        echo "grub-pc grub-pc/install_devices string /dev/$BOOT_DISK" | debconf-set-selections
        log "grub-pc preconfigurado en /dev/$BOOT_DISK"
    else
        warn "No se pudo detectar disco de boot, grub-pc podria fallar"
    fi
fi

warn "================= apt-get update -y ================="
apt-get update -y
warn "================= apt-get upgrade -y ================="
apt-get upgrade -y
warn "================= apt-get dist-upgrade -y ================="
apt-get dist-upgrade -y

DEPS="curl wget git sudo build-essential ca-certificates gnupg lsb-release \
      unzip htop tmux vim net-tools openssh-server openssl"

apt-get install -y $DEPS
log "Sistema actualizado y dependencias instaladas"

# ============================================================
# 2. INSTALACION DE SOFTWARE
# ============================================================
echo ""
echo "========== 2. INSTALACION DE SOFTWARE =========="

# --- 2a. Podman ---
if ! command -v podman &>/dev/null; then
    apt-get install -y podman
    log "Podman instalado"
else
    warn "Podman ya estaba instalado: $(podman --version)"
fi

# --- 2a.1 Podman Compose ---
if ! command -v podman-compose &>/dev/null; then
    apt-get install -y podman-compose
    log "Podman Compose instalado"
else
    warn "Podman Compose ya estaba instalado: $(podman-compose version 2>/dev/null | head -1)"
fi

# --- 2b. HTTPie ---
if ! command -v http &>/dev/null; then
    apt-get install -y httpie
    log "HTTPie instalado"
else
    warn "HTTPie ya estaba instalado: $(http --version 2>/dev/null | head -1)"
fi

# --- 2c. Caddy ---
if ! command -v caddy &>/dev/null; then
    apt-get install -y debian-keyring debian-archive-keyring
    if [ ! -f /usr/share/keyrings/caddy-stable-archive-keyring.gpg ]; then
        curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
            | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    fi
    if [ ! -f /etc/apt/sources.list.d/caddy-stable.list ]; then
        curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
            | tee /etc/apt/sources.list.d/caddy-stable.list
    fi
    apt-get update -y
    apt-get install -y caddy
    log "Caddy instalado"
else
    warn "Caddy ya estaba instalado: $(caddy version)"
fi

systemctl disable caddy
systemctl stop caddy 2>/dev/null || true
log "Caddy instalado pero detenido y deshabilitado (iniciar manualmente cuando se necesite: systemctl enable --now caddy)"

# --- 2d. Speedtest CLI (Ookla) ---
if ! command -v speedtest &>/dev/null; then
    TMPSCRIPT=$(mktemp)
    curl -sf https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh -o "$TMPSCRIPT"
    bash "$TMPSCRIPT"
    rm -f "$TMPSCRIPT"
    apt-get install -y speedtest
    log "Speedtest instalado"
else
    warn "Speedtest ya estaba instalado"
fi

# ============================================================
# 3. CREAR USUARIO SEGURO
# ============================================================
echo ""
echo "========== 3. CREAR USUARIO 'demo' =========="

if ! id "demo" &>/dev/null; then
    useradd -m -d /home/demo -s /bin/bash demo
    log "Usuario 'demo' creado"
else
    warn "Usuario 'demo' ya existe"
fi

echo "demo:${USER_PASS}" | chpasswd
usermod -aG sudo demo
chage -d 0 demo
log "Contraseña asignada, grupo sudo agregado, cambio forzado en primer login"

# --- Habilitar sesion systemd para podman rootless ---
apt-get install -y dbus-user-session
loginctl enable-linger demo
log "Lingering habilitado y dbus-user-session instalado para podman rootless"

# --- Alias personalizado para root y demo ---
ALIAS_LINE='alias l="ls -lah --group-directories-first --time-style=long-iso --color=auto"'
for BASHRC in /root/.bashrc /home/demo/.bashrc; do
    echo "$ALIAS_LINE" >> "$BASHRC"
done
log "Alias 'l' agregado en .bashrc de root y demo"

# ============================================================
# 4. CONFIGURACION SSH DEL USUARIO
# ============================================================
echo ""
echo "========== 4. CONFIGURACION SSH DE 'demo' =========="

SSH_DIR="/home/demo/.ssh"
mkdir -p "$SSH_DIR"
echo "$SSH_PUBKEY" > "$SSH_DIR/authorized_keys"
chmod 700 "$SSH_DIR"
chmod 600 "$SSH_DIR/authorized_keys"
chown -R demo:demo "$SSH_DIR"
log "Clave publica inyectada y permisos SSH configurados"

# ============================================================
# 5. CONFIGURAR ~/.ssh/config
# ============================================================
echo ""
echo "========== 5. CONFIGURAR SSH CONFIG =========="

SSH_CONFIG="$SSH_DIR/config"
cat > "$SSH_CONFIG" <<'SSHCONF'
# --- GitHub ---
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github
    IdentitiesOnly yes
    AddKeysToAgent yes

# --- Configuracion general ---
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    AddKeysToAgent yes
SSHCONF

chmod 600 "$SSH_CONFIG"
chown demo:demo "$SSH_CONFIG"
log "Archivo ~/.ssh/config configurado"

# --- Habilitar autenticacion por llave en sshd ---
SSHD_CONF="/etc/ssh/sshd_config"
declare -A SSHD_OPTS=(
    ["PubkeyAuthentication"]="yes"
    ["AuthorizedKeysFile"]=".ssh/authorized_keys"
)

for key in "${!SSHD_OPTS[@]}"; do
    val="${SSHD_OPTS[$key]}"
    if grep -qE "^#?${key}\b" "$SSHD_CONF"; then
        sed -i "s|^#*${key}.*|${key} ${val}|" "$SSHD_CONF"
    else
        echo "${key} ${val}" >> "$SSHD_CONF"
    fi
done
systemctl restart sshd
log "sshd configurado: autenticacion por llave habilitada para usuario demo (root y password siguen activos)"

# ============================================================
# 6. CONFIGURACION DE PODMAN
# ============================================================
echo ""
echo "========== 6. CONFIGURACION PODMAN =========="

# Inicializar registries si no existe
REGISTRIES_CONF="/etc/containers/registries.conf"
if ! grep -q "docker.io" "$REGISTRIES_CONF" 2>/dev/null; then
    cat >> "$REGISTRIES_CONF" <<'EOF'

unqualified-search-registries = ["docker.io"]
EOF
    log "Registries de Podman configurados"
else
    warn "Registries ya configurados"
fi

# Verificar Podman
podman info >/dev/null 2>&1
log "Podman funcionando correctamente"


# ============================================================
# 7. VALIDACIONES FINALES
# ============================================================
echo ""
echo "========== 7. VALIDACIONES FINALES =========="
echo ""

# Servicios
echo "--- Servicios ---"
for svc in caddy ssh; do
    STATUS=$(systemctl is-active "$svc" 2>/dev/null || echo "inactivo")
    if [ "$STATUS" = "active" ]; then
        log "$svc: activo"
    else
        warn "$svc: $STATUS"
    fi
done

# Usuario
echo ""
echo "--- Usuario 'demo' ---"
if id "demo" &>/dev/null; then
    log "Usuario existe: $(id demo)"
else
    err "Usuario 'demo' NO encontrado"
fi

# Podman
echo ""
echo "--- Podman ---"
podman --version
podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "--- Volumenes Podman ---"
podman volume ls

# SSH
echo ""
echo "--- SSH de 'demo' ---"
ls -la /home/demo/.ssh/

# ============================================================
# RESUMEN FINAL
# ============================================================
echo ""
echo "============================================"
echo "  RESUMEN DE CONFIGURACION"
echo "============================================"
echo ""
echo "  Sistema     : Debian 12 (Bookworm) actualizado"
echo "  Caddy       : $(caddy version 2>/dev/null | head -1)"
echo "  Podman      : $(podman --version 2>/dev/null)"
echo ""
echo "  Usuario     : demo"
echo "  Home        : /home/demo"
echo "  Shell       : /bin/bash"
echo "  Grupos      : $(groups demo 2>/dev/null)"
echo ""
echo ""
echo "============================================"
echo "  CREDENCIALES (GUARDAR EN LUGAR SEGURO)"
echo "============================================"
echo ""
echo "  Usuario 'demo' password : ${USER_PASS}"
echo ""
echo "  Clave publica SSH inyectada en /home/demo/.ssh/authorized_keys"
echo "============================================"
echo "  NOTA: El usuario 'demo' debera cambiar su"
echo "  contraseña en el primer login. Puede generar una nueva clave"
echo "  corriendo: openssl rand -base64 16 | tr -d '/+=' | head -c 20"
echo "============================================"
echo ""

# Limpiar cache de apt
warn "Limpieza de apt-get"
apt-get clean
apt-get autoremove -y >/dev/null 2>&1

log "Configuracion completada exitosamente"
