
### Instrucciones

### 1. Subir el script al servidor

Desde tu máquina local:
```bash
ETHDEMO=186.64.113.247
SSH_PORT=26286
scp -P ${SSH_PORT} ~/git/infrastructure/installations/linux/setup-debian12-clean.sh root@${ETHDEMO}:/root/setup.sh
```

### 2. Ejecutar el instalador

Conectar al servidor como root y ejecutar el script pasando tu clave pública SSH como argumento (La ejecución del script toma unos 15 minutos):
```bash
ssh root@${ETHDEMO} -p${SSH_PORT}
# Password en 1password

chmod +x ~/setup.sh
time ~/setup.sh 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFyr4dNms1k8u7zfZsqcSj2Duxrc6SyXW4ErDwbwZjRn demo@tu_usuario'
```

> El script genera una contraseña temporal para el usuario `demo` y la muestra al final.
> El usuario deberá cambiarla en el primer login.

### 3. Verificar acceso con el usuario demo

Desde tu máquina local, verificar que la clave SSH funciona:
```bash
ssh -i ~/.ssh/ethervs_demo demo@${ETHDEMO} -p${SSH_PORT}
```

### 4. Deploy de hexagono

Hexagono es un aplicativo que se monta con podman-compose en el usuario `demo`.

#### 4a. Crear directorio de trabajo
```bash
su - demo
mkdir ~/temp
```

#### 4b. Subir archivos desde tu máquina local
```bash
scp -i ~/.ssh/ethervs_demo -P ${SSH_PORT} \
    ~/git/infrastructure/hexagono/hexagono_dump.sql \
    ~/git/infrastructure/hexagono/.env \
    ~/git/infrastructure/hexagono/.envvars \
    ~/git/infrastructure/hexagono/compose.yaml \
    demo@${ETHDEMO}:/home/demo/temp/
```

#### 4c. Cargar variables de entorno
```bash
source /home/demo/temp/.envvars
```

#### 4d. Login en ghcr.io
```bash
echo $GITHUB_TOKEN | podman login ghcr.io -u GITHUB_USER --password-stdin
```

#### 4e. Levantar los contenedores (Esto toma unos 10 minutos)
```bash
cd ~/temp
clear; time podman-compose up -d
```
