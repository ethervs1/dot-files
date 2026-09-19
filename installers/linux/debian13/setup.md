
### Instrucciones

### 1. Subir el script al servidor

Desde tu máquina local:
```bash
ETHDEMO=186.64.113.247
SSH_PORT=26286
scp -P ${SSH_PORT} /Users/ethervs/Documents/_git/dot-files/installers/linux/debian12/setup.sh root@${ETHDEMO}:/root/setup.sh
```

### 2. Ejecutar el instalador

Conectar al servidor como root y ejecutar el script pasando tu clave pública SSH como argumento (La ejecución del script toma unos 15 minutos):
```bash
ssh root@${ETHDEMO} -p${SSH_PORT}
# Password en 1password

chmod +x ~/setup.sh
time ~/setup.sh 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBLS2vJAIXUm61ddR6p5mIO8rwLJ5VCekCvGl0ywrbkZ ethervs-demo'
```

> El script genera una contraseña temporal para el usuario `demo` y la muestra al final.
> El usuario deberá cambiarla en el primer login.

### 3. Verificar acceso con el usuario demo

La llave se encuentra en 1password y se usa su ssh-agent, solo debes hacer ssh, y el sistema usara la llave correspondiente
```bash
ETHDEMO=186.64.113.247
SSH_PORT=26286
ssh demo@186.64.113.247 -p26286;
```

### 4. Deploy de hexagono

Hexagono es un aplicativo que se monta con podman-compose en el usuario `demo`.

#### 4a. Subir archivos desde tu máquina local
```bash
ETHDEMO=186.64.113.247 \
SSH_PORT=26286 \
scp -P ${SSH_PORT} \
    ~/git/infrastructure/hexagono/hexagono_dump.sql \
    ~/git/infrastructure/hexagono/.env \
    ~/git/infrastructure/hexagono/.envvars \
    ~/git/infrastructure/hexagono/compose.yaml \
    demo@${ETHDEMO}:/home/demo/temp/
```

#### 4b. Cargar variables de entorno
```bash
source /home/demo/temp/.envvars
```

#### 4c. Login en ghcr.io
```bash
echo $GITHUB_TOKEN | podman login ghcr.io -u GITHUB_USER --password-stdin
```

#### 4d. Levantar los contenedores (Esto toma unos 10 minutos)
```bash
cd ~/temp
clear; time podman-compose up -d
```

### 5. Configurar Password Store (pass)

Password Store es un administrador de contraseñas basado en GPG. Se instala automáticamente con setup.sh.

#### 5a. Opción rápida: Automatizar inicialización

Subir y ejecutar el script de automatización:

```bash
# Desde tu máquina local
scp -P ${SSH_PORT} /path/to/pass-init.sh demo@${ETHDEMO}:/tmp/pass-init.sh

# Conectar como demo y ejecutar
ssh demo@${ETHDEMO} -p${SSH_PORT}
bash /tmp/pass-init.sh
```

**Con opciones de automatización:**
```bash
# Usar GPG ID específico y git remote
bash /tmp/pass-init.sh --gpg-id YOUR_GPG_ID --git-remote git@github.com:user/password-store.git
```

El script automáticamente:
- Detecta claves GPG disponibles (con selección interactiva si hay varias)
- Inicializa el vault de pass
- Crea estructura de carpetas recomendada
- Opcionalmente inicializa repositorio git

#### 5c. Manual: Generar una clave GPG (si no tienes una)

Conectar como usuario `demo`:
```bash
ssh demo@${ETHDEMO} -p${SSH_PORT}
```

Generar una nueva clave GPG:
```bash
gpg --full-generate-key
# Seleccionar: RSA (default)
# Tamaño: 4096 bits
# Validez: 0 (sin expiración) o tu preferencia
# Nombre real: Tu nombre
# Email: tu-email@example.com
# Passphrase: contraseña segura
```

Ver tus claves:
```bash
gpg --list-keys
# Copiar el KEY_ID (ej: 3AA5C34371567BD2)
```

#### 5d. Inicializar el vault de Password Store (manual)

```bash
pass init KEY_ID
# Ejemplo:
# pass init 3AA5C34371567BD2
```

Verificar inicialización:
```bash
pass
# Debería mostrar: Password Store
#   └── No passwords in store.
```

#### 5e. Agregar credenciales al vault

**Opción 1: Interactivo (genera contraseña aleatoria)**
```bash
pass generate mi-app/database
# Genera una contraseña de 25 caracteres y la encripta
# Para especificar longitud:
pass generate mi-app/database 32
```

**Opción 2: Manual (ingresar contraseña)**
```bash
pass insert mi-app/api-key
# Te pedirá que escribas la contraseña (sin echo)
# Confirmar ingresándola de nuevo
```

**Opción 3: Agregar con metadatos**
```bash
pass insert -m mi-app/database
# -m: permite ingresar múltiples líneas (password + detalles)
# Primera línea: contraseña
# Siguientes líneas: usuario, URL, notas, etc.
```

#### 5f. Gestionar credenciales

**Ver todas las contraseñas almacenadas:**
```bash
pass
# Estructura de árbol
```

**Ver una contraseña específica:**
```bash
pass mi-app/database
# Mostrar en terminal
```

**Copiar al clipboard (90 segundos de timeout):**
```bash
pass -c mi-app/database
# Copia contraseña y auto-borra después de 90s
```

**Editar una credencial:**
```bash
pass edit mi-app/database
# Abre en tu editor (vi/vim por defecto)
```

**Eliminar una credencial:**
```bash
pass rm mi-app/database
# Pide confirmación
```

**Generar OTP (si la credencial incluye secret):**
```bash
# Agregar credencial con secret:
pass otp add -s mi-app/2fa
# Luego:
pass otp mi-app/2fa
```

#### 5g. Sincronizar vault con Git (opcional)

Para versionar y respaldar tu vault en un repositorio Git privado:

```bash
# Inicializar repo git en ~/.password-store/
pass git init
# Crear repositorio privado en GitHub/GitLab
pass git remote add origin git@github.com:tu-usuario/password-store.git
pass git push -u origin main

# Después, cualquier cambio en pass se commitea automáticamente:
pass insert nueva-cred
# pass commitea automáticamente
```

#### 5h. Estructura recomendada de vault

```
~/.password-store/
├── work/
│   ├── github
│   ├── gitlab
│   └── api-keys/
│       ├── external-api-1
│       └── external-api-2
├── infra/
│   ├── databases/
│   │   ├── postgres-prod
│   │   └── postgres-dev
│   └── servers/
│       └── ethdemo
├── personal/
│   ├── email
│   └── banking
└── apps/
    ├── hexagono
    └── otro-proyecto
```

#### 5i. Configuración avanzada (opcional)

**Cambiar editor por defecto:**
```bash
export EDITOR=nano
# O permanente en ~/.bashrc:
echo 'export EDITOR=nano' >> ~/.bashrc
```

**Usar con ssh-agent (guardar passphrases):**
```bash
# Agregar a ~/.bashrc:
gpg-connect-agent updatestartuptty /bye > /dev/null 2>&1
```

**Autocompletar en bash:**
```bash
# Ya incluido en package pass, test con:
pass <TAB><TAB>
```
