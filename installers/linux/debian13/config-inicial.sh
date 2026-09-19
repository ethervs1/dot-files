
#!/usr/bin/env bash
# ==============================================================================
# Script de Configuración de Servidor Debian 24/7 para Lenovo ThinkPad X260
# ==============================================================================
# Ejemplo ejecucion: sudo ./setup.sh 2222
# sudo reboot

set -euo pipefail

# Asegurar ejecucion como root
if [ "$EUID" -ne 0 ]; then
  echo "[!] Este script debe ejecutarse con privilegios de root (sudo)." >&2
  exit 1
fi

SSH_PORT="${1:-2222}"

echo "=================================================================="
echo "    INICIANDO CONFIGURACIÓN SERVIDOR 24/7 EN DEBIAN"
echo "=================================================================="
echo ""

# 1. Configuración de SSH (Puerto personalizado)
echo "[1/4] Configurando demonio SSH en el puerto $SSH_PORT..."
SSHD_CONFIG="/etc/ssh/sshd_config"

if [ -f "$SSHD_CONFIG" ]; then
    if [ ! -f "${SSHD_CONFIG}.bak" ]; then
        cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak"
    fi
    sed -i -E 's/^#?Port [0-9]+/Port '$SSH_PORT'/' "$SSHD_CONFIG"
    if sshd -t; then
        systemctl restart ssh
        echo "[+] SSH reconfigurado correctamente en puerto $SSH_PORT."
    else
        echo "[!] Error en la sintaxis de sshd_config. Restaurando copia..."
        cp "${SSHD_CONFIG}.bak" "$SSHD_CONFIG"
        systemctl restart ssh
    fi
else
    echo "[!] /etc/ssh/sshd_config no encontrado. Instalando openssh-server..."
    apt-get update && apt-get install -y openssh-server
    sed -i -E 's/^#?Port [0-9]+/Port '$SSH_PORT'/' "$SSHD_CONFIG"
    systemctl restart ssh
fi

# 2. Configuración de systemd-logind (Ignorar tapa cerrada)
echo ""
echo "[2/4] Desactivando suspensión e hibernación al cerrar la tapa..."
LOGIND_CONF="/etc/systemd/logind.conf"

if [ -f "$LOGIND_CONF" ]; then
    sed -i -E 's/^#?HandleLidSwitch=.*/HandleLidSwitch=ignore/' "$LOGIND_CONF"
    sed -i -E 's/^#?HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=ignore/' "$LOGIND_CONF"
    sed -i -E 's/^#?HandleLidSwitchDocked=.*/HandleLidSwitchDocked=ignore/' "$LOGIND_CONF"
    sed -i -E 's/^#?IdleAction=.*/IdleAction=ignore/' "$LOGIND_CONF"
    systemctl restart systemd-logind
    echo "[+] logind.conf actualizado e ignora el cierre de tapa."
fi

# Enmascarar targets de suspensión del kernel
echo "[+] Enmascarando targets de suspensión e hibernación..."
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# 3. Desactivación de ahorro de energía USB (Autosuspend para el DAS)
echo ""
echo "[3/4] Desactivando autosuspend de puertos USB para el DAS..."
GRUB_CONF="/etc/default/grub"

if [ -f "$GRUB_CONF" ]; then
    if ! grep -q "usbcore.autosuspend=-1" "$GRUB_CONF"; then
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="usbcore.autosuspend=-1 /' "$GRUB_CONF"
        sed -i 's/  */ /g' "$GRUB_CONF"
        update-grub
        echo "[+] Parámetro usbcore.autosuspend=-1 añadido a GRUB."
    else
        echo "[i] El parámetro usbcore.autosuspend=-1 ya existía en GRUB."
    fi
fi

# 4. Limpieza de gestores energéticos agresivos (TLP)
echo ""
echo "[4/4] Removiendo paquetes de ahorro de energía (TLP)..."
if dpkg -l | grep -q tlp; then
    apt-get remove --purge -y tlp
    echo "[+] Paquete TLP removido."
else
    echo "[i] TLP no está instalado."
fi

echo ""
echo "=================================================================="
echo "    CONFIGURACIÓN COMPLETADA CON ÉXITO"
echo "=================================================================="
echo " RESUMEN DE CAMBIOS:"
echo "  - Puerto SSH asignado: $SSH_PORT"
echo "  - Cierre de tapa: IGNORADO (no hibernera ni suspenderá)"
echo "  - Puertos USB: Autosuspend desactivado (modo 24/7 activo)"
echo ""
echo " RECOMENDACIÓN: Ejecuta 'sudo reboot' para aplicar los cambios de GRUB."
echo "=================================================================="
