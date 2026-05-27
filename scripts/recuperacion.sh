#!/bin/bash
# ============================================================
# Script: recuperacion.sh
# Descripción: Recuperación ante fallos - CORPAMAG
# Autor: Juan Camilo Lopez
# ============================================================

LOG_DIR="/var/log/corpamag"
LOG_FILE="$LOG_DIR/recuperacion.log"
PROYECTO="/home/juan-camilo-lopez-fuentes/corpamag-infra"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

separador() {
    echo "=================================================" \
        | tee -a "$LOG_FILE"
}

separador
log " Inicio de Recuperación CORPAMAG"
separador

# -------------------------------------------------------
# VERIFICAR Y RECUPERAR CONTENEDORES CAÍDOS
# -------------------------------------------------------
log "Verificando contenedores..."

contenedores=(
    "corpamag-web"
    "corpamag-web2"
    "corpamag-lb"
    "corpamag-db"
    "corpamag-files"
    "corpamag-ntp"
    "corpamag-ssh"
)

for contenedor in "${contenedores[@]}"; do
    estado=$(sudo docker inspect \
        --format='{{.State.Status}}' \
        "$contenedor" 2>/dev/null)

    if [[ "$estado" == "running" ]]; then
        log "✓ $contenedor: activo"
    else
        log "✗ $contenedor: caído - intentando recuperar..."
        sudo docker start "$contenedor" 2>/dev/null && \
            log "✓ $contenedor: recuperado exitosamente" || \
            log "✗ $contenedor: no se pudo recuperar"
    fi
done

# -------------------------------------------------------
# VERIFICAR Y RECUPERAR RAID
# -------------------------------------------------------
log ""
log "Verificando RAID..."
if cat /proc/mdstat | grep -q "md0"; then
    log "✓ RAID activo"
else
    log "✗ RAID caído - intentando recuperar..."
    sudo losetup -f --show \
        /opt/corpamag-discos/disco1.img 2>/dev/null
    sudo losetup -f --show \
        /opt/corpamag-discos/disco2.img 2>/dev/null
    sudo mdadm --assemble /dev/md0 --scan 2>/dev/null && \
        log "✓ RAID recuperado" || \
        log "✗ RAID no se pudo recuperar"
fi

# -------------------------------------------------------
# VERIFICAR Y RECUPERAR VOLÚMENES LVM
# -------------------------------------------------------
log ""
log "Verificando volúmenes LVM..."

for volumen in database archivos backups; do
    if mountpoint -q /data/$volumen; then
        log "✓ /data/$volumen: montado"
    else
        log "✗ /data/$volumen: desmontado - montando..."
        sudo mount /dev/corpamag-vg/lv-$volumen \
            /data/$volumen 2>/dev/null && \
            log "✓ /data/$volumen: montado exitosamente" || \
            log "✗ /data/$volumen: no se pudo montar"
    fi
done

# -------------------------------------------------------
# VERIFICAR FIREWALL
# -------------------------------------------------------
log ""
log "Verificando firewall..."
reglas=$(sudo iptables -L INPUT --line-numbers -n | wc -l)
if [[ $reglas -gt 3 ]]; then
    log "✓ Firewall activo ($reglas reglas)"
else
    log "✗ Firewall sin reglas - aplicando..."
    sudo bash "$PROYECTO/firewall/iptables_rules.sh" \
        >> "$LOG_FILE" 2>&1
    log "✓ Firewall recuperado"
fi

# -------------------------------------------------------
# RESUMEN FINAL
# -------------------------------------------------------
log ""
separador
log " Estado final de la infraestructura:"
separador
sudo docker-compose -f "$PROYECTO/docker-compose.yml" \
    ps | tee -a "$LOG_FILE"
separador
log " Recuperación completada"
separador
