#!/bin/bash
# ============================================================
# Script: usuarios_permisos.sh
# Descripción: Gestión de usuarios y permisos CORPAMAG
# Incluye: SETUID, SETGID, Sticky bit
# Autor: Juan Camilo Lopez
# ============================================================

set -e

echo "=============================================="
echo "  Configurando Usuarios y Permisos CORPAMAG"
echo "=============================================="

# -------------------------------------------------------
# PASO 1: Crear grupos
# -------------------------------------------------------
echo "[1/5] Creando grupos..."

groupadd -f corpamag_admins
groupadd -f corpamag_funcionarios
groupadd -f corpamag_readonly

echo "✓ Grupos creados:"
echo "  - corpamag_admins"
echo "  - corpamag_funcionarios"
echo "  - corpamag_readonly"

# -------------------------------------------------------
# PASO 2: Crear usuarios
# -------------------------------------------------------
echo "[2/5] Creando usuarios..."

# Administrador TI
if ! id "admin_ti" &>/dev/null; then
    useradd -m -s /bin/bash \
        -G corpamag_admins,sudo \
        -c "Administrador TI CORPAMAG" \
        admin_ti
    echo "admin_ti:Admin2024!" | sudo chpasswd
    echo "  ✓ Usuario admin_ti creado"
else
    echo "  ℹ Usuario admin_ti ya existe"
fi

# Funcionario ambiental
if ! id "func_ambiental" &>/dev/null; then
    useradd -m -s /bin/bash \
        -G corpamag_funcionarios \
        -c "Funcionario Ambiental CORPAMAG" \
        func_ambiental
    echo "func_ambiental:Func2024!" | sudo chpasswd
    echo "  ✓ Usuario func_ambiental creado"
else
    echo "  ℹ Usuario func_ambiental ya existe"
fi

# Auditor (solo lectura)
if ! id "auditor" &>/dev/null; then
    useradd -m -s /bin/bash \
        -G corpamag_readonly \
        -c "Auditor CORPAMAG" \
        auditor
    echo "auditor:Audit2024!" | sudo chpasswd
    echo "  ✓ Usuario auditor creado"
else
    echo "  ℹ Usuario auditor ya existe"
fi

# -------------------------------------------------------
# PASO 3: Crear estructura de directorios
# -------------------------------------------------------
echo "[3/5] Creando estructura de directorios..."

mkdir -p /srv/corpamag/{documentos,backups,reportes,compartido,scripts}

echo "  ✓ Directorios creados en /srv/corpamag/"

# -------------------------------------------------------
# PASO 4: Asignar propietarios y permisos básicos
# -------------------------------------------------------
echo "[4/5] Asignando permisos..."

# Backups: solo admins pueden leer y escribir
chown -R root:corpamag_admins /srv/corpamag/backups
chmod 770 /srv/corpamag/backups
echo "  ✓ /backups → chmod 770 (solo admins)"

# Scripts: solo admins pueden ejecutar
chown -R root:corpamag_admins /srv/corpamag/scripts
chmod 750 /srv/corpamag/scripts
echo "  ✓ /scripts → chmod 750 (admins ejecutan)"

# Documentos: funcionarios leen y escriben
chown -R root:corpamag_funcionarios /srv/corpamag/documentos
chmod 770 /srv/corpamag/documentos
echo "  ✓ /documentos → chmod 770 (funcionarios)"

# Reportes: solo lectura para auditores
chown -R root:corpamag_readonly /srv/corpamag/reportes
chmod 750 /srv/corpamag/reportes
echo "  ✓ /reportes → chmod 750 (solo lectura)"

# -------------------------------------------------------
# PASO 5: Permisos especiales
# -------------------------------------------------------
echo "[5/5] Aplicando permisos especiales..."

# --- STICKY BIT en /compartido ---
# Evita que usuarios borren archivos de otros usuarios
chmod 1777 /srv/corpamag/compartido
echo ""
echo "  ✓ STICKY BIT aplicado en /compartido"
echo "    Efecto: usuarios no pueden borrar archivos ajenos"
echo "    Verificación:"
ls -ld /srv/corpamag/compartido
# Debe mostrar drwxrwxrwt (la 't' indica sticky bit)

# --- SETGID en /documentos ---
# Archivos nuevos heredan el grupo del directorio
chmod g+s /srv/corpamag/documentos
echo ""
echo "  ✓ SETGID aplicado en /documentos"
echo "    Efecto: archivos nuevos heredan grupo corpamag_funcionarios"
echo "    Verificación:"
ls -ld /srv/corpamag/documentos
# Debe mostrar drwxrws--- (la 's' en grupo indica SETGID)

# --- SETUID en script de backup ---
# Permite que cualquier admin ejecute el backup como root
touch /srv/corpamag/scripts/backup_runner.sh
chown root:corpamag_admins /srv/corpamag/scripts/backup_runner.sh
chmod 4750 /srv/corpamag/scripts/backup_runner.sh
echo ""
echo "  ✓ SETUID aplicado en backup_runner.sh"
echo "    Efecto: se ejecuta con privilegios de root"
echo "    Verificación:"
ls -l /srv/corpamag/scripts/backup_runner.sh
# Debe mostrar -rwsr-x--- (la 's' en usuario indica SETUID)

# -------------------------------------------------------
# Resumen final
# -------------------------------------------------------
echo ""
echo "=============================================="
echo "✓ Usuarios y permisos configurados"
echo "=============================================="
echo ""
echo "Usuarios creados:"
echo "  admin_ti        → grupo: corpamag_admins"
echo "  func_ambiental  → grupo: corpamag_funcionarios"
echo "  auditor         → grupo: corpamag_readonly"
echo ""
echo "Estructura de permisos:"
ls -la /srv/corpamag/
echo ""
echo "Verificación de permisos especiales:"
echo "  Sticky bit  → /srv/corpamag/compartido"
echo "  SETGID      → /srv/corpamag/documentos"
echo "  SETUID      → /srv/corpamag/scripts/backup_runner.sh"
