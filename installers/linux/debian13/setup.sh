
#!/usr/bin/env bash
set -euo pipefail
clear

# ============================================================
# Setup completo para Debian 13 - Servidor limpio
# ============================================================
#
# INSTRUCCIONES DE USO:
#   bash setup.sh
#
# REQUISITOS:
#   - Ejecutar como root o con sudo
#   - Sistema Debian 13 limpio
#   - Conexión a Internet
#
# CARACTERÍSTICAS:
#   - Actualización completa del sistema
#   - Instalación de Docker + Docker Compose
#   - Instalación de Samba (NAS con compartido en /mnt/share)
#   - Instalación de herramientas útiles (HTTPie, Pass, Speedtest)
#   - Idempotente: se puede ejecutar múltiples veces sin romper nada
#
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

echo ""
echo "============================================"
echo "  CONFIGURACION SERVIDOR DEBIAN 13"
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
# Debian 13 puede usar formato DEB822 (.sources) o tradicional (.list)
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

# --- 2a. Docker (desde repositorio oficial) ---
if ! command -v docker &>/dev/null; then
    # Agregar repositorio oficial de Docker
    apt-get install -y ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    if [ ! -f /etc/apt/keyrings/docker.asc ]; then
        curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
        chmod a+r /etc/apt/keyrings/docker.asc
    fi

    if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | \
            tee /etc/apt/sources.list.d/docker.list > /dev/null
    fi

    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    log "Docker instalado desde repositorio oficial"
else
    warn "Docker ya estaba instalado: $(docker --version)"
fi

# --- Iniciar Docker como servicio ---
systemctl enable docker
systemctl start docker
log "Docker daemon iniciado y habilitado"

# --- 2b. HTTPie ---
if ! command -v http &>/dev/null; then
    apt-get install -y httpie
    log "HTTPie instalado"
else
    warn "HTTPie ya estaba instalado: $(http --version 2>/dev/null | head -1)"
fi

# --- 2c. Pass (Password Store) ---
if ! command -v pass &>/dev/null; then
    apt-get install -y pass
    log "Pass (Password Store) instalado"
else
    warn "Pass (Password Store) ya estaba instalado: $(pass version 2>/dev/null || echo 'installed')"
fi

# --- 2d. Samba (File Sharing) ---
if ! command -v smbclient &>/dev/null; then
    apt-get install -y samba samba-common-bin
    log "Samba instalado"
else
    warn "Samba ya estaba instalado"
fi

# Crear partición compartida de Samba
SAMBA_PATH="/mnt/share"
if [ ! -d "$SAMBA_PATH" ]; then
    mkdir -p "$SAMBA_PATH"
    chmod 755 "$SAMBA_PATH"
    chown nobody:nogroup "$SAMBA_PATH"
    log "Directorio Samba creado en $SAMBA_PATH"
else
    warn "Directorio Samba ya existe"
fi

# Configurar smb.conf
SAMBA_CONF="/etc/samba/smb.conf"
if ! grep -q "^\[share\]" "$SAMBA_CONF" 2>/dev/null; then
    cat >> "$SAMBA_CONF" <<'SAMBACONF'

[share]
    comment = Samba Share
    path = /mnt/share
    browseable = Yes
    writable = Yes
    read only = No
    create mask = 0755
    directory mask = 0755
    guest ok = Yes
    guest only = no
    force user = nobody
    force group = nogroup
SAMBACONF
    log "Configuración de [share] agregada a smb.conf"
else
    warn "Configuración [share] ya existe en smb.conf"
fi

# Validar y reiniciar Samba
testparm -s > /dev/null 2>&1 && log "Configuración de Samba válida" || err "Error en configuración de Samba"
systemctl enable smbd nmbd
systemctl restart smbd nmbd
log "Servicios Samba (smbd, nmbd) iniciados y habilitados"

# --- 2e. Speedtest CLI (Ookla) ---
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
# 3. VALIDACIONES FINALES
# ============================================================
echo ""
echo "========== 3. VALIDACIONES FINALES =========="
echo ""

# Servicios
echo "--- Servicios ---"
for svc in docker smbd nmbd; do
    STATUS=$(systemctl is-active "$svc" 2>/dev/null || echo "inactivo")
    if [ "$STATUS" = "active" ]; then
        log "$svc: activo"
    else
        warn "$svc: $STATUS"
    fi
done

# Docker
echo ""
echo "--- Docker ---"
docker --version
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "--- Volumenes Docker ---"
docker volume ls

# Samba
echo ""
echo "--- Samba ---"
smbclient --version 2>/dev/null | head -1
echo "  Directorio compartido: /mnt/share"
ls -lad /mnt/share

# ============================================================
# RESUMEN FINAL
# ============================================================
echo ""
echo "============================================"
echo "  RESUMEN DE CONFIGURACION"
echo "============================================"
echo ""
echo "  Sistema     : Debian 13 actualizado"
echo "  Docker      : $(docker --version 2>/dev/null)"
echo "  Samba       : $(smbclient --version 2>/dev/null | head -1)"
echo ""
echo "  Compartido Samba: /mnt/share"
echo "    Acceso: //hostname/share"
echo "    Acceso local: smb://localhost/share"
echo ""
echo "============================================"
echo ""

# Limpiar cache de apt
warn "Limpieza de apt-get"
apt-get clean
apt-get autoremove -y >/dev/null 2>&1

log "Configuracion completada exitosamente"
