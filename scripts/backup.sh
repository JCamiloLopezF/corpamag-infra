#!/bin/bash
# ============================================================
# Script: backup.sh
# Descripción: Backup automatizado de servicios CORPAMAG
# Autor: Juan Camilo Lopez
# ============================================================

set -e

# ---- CONFIGURACIÓN ----
BACKUP_DIR="/data/backups"
FECHA=$(date +"%Y%m%d_%H%M%S")
LOG_DIR="/var/log/corpamag"
LOG_FILE="$LOG_DIR/backup_$FECHA.log"
DB_CONTAINER="corpamag-db"
DB_NAME="corpamag_db"
DB_USER="corpamag_admin"
RETENCION_DIAS=7

# ---- FUNCIONES ----
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

verificar_espacio() {
    local disponible=$(df "$BACKUP_DIR" | tail -1 | awk '{print $4}')
    if [[ $disponible -lt 51200 ]]; then
        log "ERROR: Espacio insuficiente en $BACKUP_DIR"
        exit 1
    fi
}

verificar_contenedor() {
    if ! sudo docker ps | grep -q "$DB_CONTAINER"; then
        log "ERROR: Contenedor $DB_CONTAINER no está corriendo"
        exit 1
    fi
}

# ---- INICIO ----
mkdir -p "$BACKUP_DIR" "$LOG_DIR"

log "=========================================="
log " Inicio de Backup CORPAMAG - $FECHA"
log "=========================================="

verificar_espacio
verificar_contenedor

# ---- BACKUP BASE DE DATOS ----
log "Realizando backup de PostgreSQL..."
sudo docker exec "$DB_CONTAINER" pg_dump \
    -U "$DB_USER" \
    -d "$DB_NAME" \
    --format=plain \
    > "$BACKUP_DIR/db_backup_$FECHA.sql"

if [[ $? -eq 0 ]]; then
    TAMANIO=$(du -sh "$BACKUP_DIR/db_backup_$FECHA.sql" | cut -f1)
    log "✓ Backup BD exitoso: db_backup_$FECHA.sql ($TAMANIO)"
else
    log "✗ ERROR en backup de BD"
    exit 1
fi

# ---- BACKUP ARCHIVOS COMPARTIDOS ----
log "Realizando backup de archivos compartidos..."
if [[ -d "/srv/corpamag/documentos" ]]; then
    tar -czf "$BACKUP_DIR/docs_backup_$FECHA.tar.gz" \
        /srv/corpamag/documentos/ 2>/dev/null
    log "✓ Backup documentos exitoso"
else
    log "⚠ Directorio documentos no encontrado, omitiendo"
fi

# ---- BACKUP CONFIGURACIONES ----
log "Guardando configuraciones Docker..."
cp /home/juan-camilo-lopez-fuentes/corpamag-infra/docker-compose.yml \
   "$BACKUP_DIR/docker-compose_$FECHA.yml"
log "✓ docker-compose.yml respaldado"

# ---- LIMPIEZA DE BACKUPS ANTIGUOS ----
log "Eliminando backups con más de $RETENCION_DIAS días..."
find "$BACKUP_DIR" -type f -mtime +"$RETENCION_DIAS" -delete
log "✓ Limpieza completada"

# ---- RESUMEN ----
log ""
log "Archivos en $BACKUP_DIR:"
ls -lh "$BACKUP_DIR" | tee -a "$LOG_FILE"
log ""
log "=========================================="
log " Backup completado exitosamente"
log "=========================================="
