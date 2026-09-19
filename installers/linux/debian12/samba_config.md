# Configuración de Samba en Debian 12

## Instalación

```bash
apt-get install -y samba samba-common-bin samba-client
```

## Preparación - Mount de partición/volumen

### Opción 1: Montar partición existente (recomendado)

**1. Identificar la partición disponible:**
```bash
lsblk
fdisk -l
```

**2. Montar la partición en /mnt/storage:**
```bash
# Crear punto de montaje
mkdir -p /mnt/storage

# Montar partición (reemplazar sdb3 con tu partición)
mount /dev/sdb3 /mnt/storage

# Verificar montaje
df -h /mnt/storage
```

**3. Hacer persistente el montaje (agregar a /etc/fstab):**
```bash
# Obtener UUID de la partición
blkid /dev/sdb3

# Editar /etc/fstab y agregar línea similar a:
# UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx /mnt/storage ext4 defaults,nofail 0 2
vim /etc/fstab

# Verificar que /etc/fstab es válido
mount -a
```

### Opción 2: Crear volumen virtual (para testing)

```bash
# Crear archivo de volumen virtual de 10GB
fallocate -l 10G /mnt/samba-volume.img

# Formatear como ext4
mkfs.ext4 /mnt/samba-volume.img

# Crear punto de montaje
mkdir -p /mnt/storage

# Montar
mount -o loop /mnt/samba-volume.img /mnt/storage

# Verificar
df -h /mnt/storage
```

## Configuración básica de Samba

### 1. Establecer permisos del directorio

```bash
chmod 755 /mnt/storage
chown nobody:nogroup /mnt/storage/multimedia
```

### 2. Configurar /etc/samba/smb.conf

Edita `/etc/samba/smb.conf` y agrega la siguiente sección al final del archivo:

```ini
[multimedia]
    comment = Multimedia Share
    path = /mnt/storage/multimedia
    browseable = Yes
    writable = Yes
    read only = No
    create mask = 0755
    directory mask = 0755
    guest ok = Yes
    guest only = no
    force user = nobody
    force group = nogroup
```

### 3. Validar configuración

```bash
testparm -s
```

Debería mostrar algo como:
```
Load smb config files from /etc/samba/smb.conf
Loaded services file OK.
...
[share]
    comment = Samba Share
    create mask = 0755
    directory mask = 0755
    force group = nogroup
    force user = nobody
    guest ok = Yes
    path = /mnt/storage
    read only = No
    writable = Yes
```

### 4. Reiniciar servicios

```bash
systemctl enable smbd nmbd
systemctl restart smbd nmbd
systemctl status smbd nmbd
```

## Diagnóstico y Pruebas

### Diagnóstico en el servidor

```bash
# 1. Verificar que Samba está corriendo
systemctl status smbd nmbd

# 2. Verificar que el directorio existe y tiene permisos
ls -ld /mnt/storage
df -h /mnt/storage

# 3. Validar la configuración de smb.conf
testparm -s

# 4. Ver los compartidos que Samba está sirviendo
smbclient -L localhost -U%

# 5. Verificar que los puertos están abiertos (139 y 445)
ss -tuln | grep -E '139|445'

# 6. Ver logs de Samba para errores
tail -50 /var/log/samba/log.smbd

# 7. Prueba de acceso local
smbclient //localhost/share -U% -c ls
```

### Firewall - Si está activo

```bash
# Ver estado del firewall
ufw status

# Si está activo, permitir Samba
ufw allow 139/tcp
ufw allow 445/tcp
ufw allow 137/udp
ufw allow 138/udp

# Recargar firewall
ufw reload
```

## Acceso desde clientes

### macOS

**Opción 1: Finder (Interfaz gráfica)**
```
cmd + K
smb://192.168.1.59/share
```

**Opción 2: Terminal**
```bash
# Conectar sin usuario (guest)
open 'smb://192.168.1.59/share'

# Montar manualmente
mkdir -p ~/Mounts/samba-share
mount_smbfs -N //192.168.1.59/share ~/Mounts/samba-share
```

### Linux

```bash
# Explorar compartido
smbclient -L //192.168.1.59/share -U%

# Montar compartido
mkdir -p ~/mnt/samba
sudo mount -t cifs //192.168.1.59/share ~/mnt/samba -o guest,uid=$UID,gid=$UID,file_mode=0755,dir_mode=0755

# Desmontar
sudo umount ~/mnt/samba
```

### Windows

```
\\192.168.1.59\share
```

## Verificación y Troubleshooting

### Verificar logs

```bash
# Logs completos de smbd
tail -f /var/log/samba/log.smbd

# Logs de nmbd
tail -f /var/log/samba/log.nmbd

# Filtrar errores
grep -i error /var/log/samba/log.smbd
```

### Problemas comunes

**Problema: "The share does not exist on the server"**
- Solución: Asegurar que `browseable = Yes` está en la configuración
- Validar con `testparm -s`
- Reiniciar servicios: `systemctl restart smbd nmbd`

**Problema: "Permission denied"**
- Verificar permisos: `ls -ld /mnt/storage`
- Debe ser accesible: `chmod 755 /mnt/storage`
- Verificar usuario: `ls -lh /mnt/storage`

**Problema: Puertos no escuchando**
```bash
ss -tuln | grep -E '139|445'
# Debe mostrar LISTEN en ambos puertos
```

**Problema: Samba no inicia**
```bash
# Ver el status detallado
systemctl status smbd nmbd

# Ver logs
tail -100 /var/log/samba/log.smbd

# Reiniciar
systemctl restart smbd nmbd
```

## Notas importantes

- El compartido está disponible en `//hostname/share` o `//IP/share`
- Acceso sin contraseña (guest ok = Yes)
- Permisos de lectura/escritura para todos
- `force user = nobody` y `force group = nogroup` fuerzan todas las conexiones a usar el usuario nobody
- Asegurar que la partición/volumen esté montado antes de iniciar Samba
- `browseable = Yes` es esencial para que aparezca en navegación de red
- Los cambios en `smb.conf` requieren reiniciar `smbd` para tomar efecto

## Parámetros de la configuración

| Parámetro | Valor | Descripción |
|-----------|-------|-------------|
| `comment` | Samba Share | Descripción del compartido |
| `path` | /mnt/storage | Ruta del directorio a compartir |
| `browseable` | Yes | Visible en navegación de red |
| `writable` | Yes | Permite escritura |
| `read only` | No | No es de solo lectura |
| `create mask` | 0755 | Permisos para archivos nuevos |
| `directory mask` | 0755 | Permisos para directorios nuevos |
| `guest ok` | Yes | Permite acceso guest (sin contraseña) |
| `guest only` | no | No obliga a conectarse como guest |
| `force user` | nobody | Fuerza usuario nobody para acceso |
| `force group` | nogroup | Fuerza grupo nogroup para acceso |
