#!/bin/bash
# ============================================================
# Script: deploy.sh
# Descripción: Despliegue automatizado de infraestructura CORPAMAG
# Autor: Juan Camilo Lopez
# ============================================================

set -e

LOG_DIR="/var/log/corpamag"
LOG_FILE="$LOG_DIR/deploy.log"
PROYECTO="/home/juan-camilo-lopez-fuentes/corpamag-infra"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=========================================="
log " Inicio de Despliegue CORPAMAG"
log "=========================================="

# ---- VERIFICAR DOCKER ----
log "Verificando Docker..."
if ! command -v docker &>/dev/null; then
    log "ERROR: Docker no está instalado"
    exit 1
fi
log "✓ Docker disponible: $(docker --version)"

# ---- VERIFICAR DOCKER COMPOSE ----
if ! command -v docker-compose &>/dev/null; then
    log "Instalando docker-compose..."
    sudo apt-get install -y docker-compose
fi
log "✓ Docker Compose disponible"

# ---- VERIFICAR RAID ----
log "Verificando RAID..."
if cat /proc/mdstat | grep -q "md0"; then
    log "✓ RAID activo"
else
    log "⚠ RAID no detectado, intentando ensamblar..."
    sudo losetup -f --show /opt/corpamag-discos/disco1.img
    sudo losetup -f --show /opt/corpamag-discos/disco2.img
    sudo mdadm --assemble /dev/md0 --scan || \
        log "⚠ No se pudo ensamblar RAID"
fi

# ---- VERIFICAR VOLÚMENES LVM ----
log "Verificando volúmenes LVM..."
if mountpoint -q /data/database; then
    log "✓ Volúmenes LVM montados"
else
    log "Montando volúmenes LVM..."
    sudo mount /dev/corpamag-vg/lv-database /data/database
    sudo mount /dev/corpamag-vg/lv-archivos /data/archivos
    sudo mount /dev/corpamag-vg/lv-backups  /data/backups
    log "✓ Volúmenes montados"
fi

# ---- IR AL DIRECTORIO DEL PROYECTO ----
cd "$PROYECTO"
log "Directorio: $(pwd)"

# ---- DETENER CONTENEDORES PREVIOS ----
log "Deteniendo contenedores previos..."
sudo docker-compose down 2>/dev/null || true
log "✓ Contenedores previos detenidos"

# ---- CONSTRUIR IMÁGENES ----
log "Construyendo imágenes Docker..."
sudo docker-compose build --no-cache
log "✓ Imágenes construidas"

# ---- LEVANTAR SERVICIOS ----
log "Iniciando servicios..."
sudo docker-compose up -d
log "✓ Servicios iniciados"

# ---- ESPERAR Y VERIFICAR ----
log "Esperando que los servicios estén listos..."
sleep 15

log "Estado final:"
sudo docker-compose ps | tee -a "$LOG_FILE"

# ---- APLICAR FIREWALL ----
log "Aplicando reglas de firewall..."
sudo bash "$PROYECTO/firewall/iptables_rules.sh" >> "$LOG_FILE" 2>&1
log "✓ Firewall aplicado"

log ""
log "=========================================="
log "✓ Despliegue completado exitosamente"
log "=========================================="
