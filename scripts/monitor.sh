#!/bin/bash
# ============================================================
# Script: monitor.sh
# Descripción: Monitoreo básico de infraestructura CORPAMAG
# Autor: Juan Camilo Lopez
# ============================================================

LOG_DIR="/var/log/corpamag"
LOG_FILE="$LOG_DIR/monitor.log"
UMBRAL_CPU=80
UMBRAL_RAM=85
UMBRAL_DISCO=90

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

separador() {
    echo "=================================================="
}

# ---- CABECERA ----
clear
separador
echo "    MONITOR DE INFRAESTRUCTURA - CORPAMAG"
echo "    $(date '+%A, %d de %B de %Y - %H:%M:%S')"
separador

# ---- CPU ----
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'.' -f1)
echo ""
echo "📊 CPU: ${CPU}% en uso"
if [[ $CPU -gt $UMBRAL_CPU ]]; then
    log "ALERTA: CPU al ${CPU}% (umbral: ${UMBRAL_CPU}%)"
    echo "   ⚠ ALERTA: CPU supera umbral crítico"
fi

# ---- RAM ----
RAM_TOTAL=$(free -m | awk 'NR==2{print $2}')
RAM_USADO=$(free -m | awk 'NR==2{print $3}')
RAM_PCT=$((RAM_USADO * 100 / RAM_TOTAL))
echo ""
echo "🧠 RAM: ${RAM_USADO}MB / ${RAM_TOTAL}MB (${RAM_PCT}%)"
if [[ $RAM_PCT -gt $UMBRAL_RAM ]]; then
    log "ALERTA: RAM al ${RAM_PCT}% (umbral: ${UMBRAL_RAM}%)"
    echo "   ⚠ ALERTA: RAM supera umbral crítico"
fi

# ---- DISCO ----
echo ""
echo "💾 Uso de disco:"
df -h | grep -E "^/dev/" | while read line; do
    uso=$(echo "$line" | awk '{print $5}' | cut -d'%' -f1)
    particion=$(echo "$line" | awk '{print $6}')
    echo "   $particion: ${uso}%"
    if [[ $uso -gt $UMBRAL_DISCO ]]; then
        log "ALERTA: Disco $particion al ${uso}%"
    fi
done

# ---- CONTENEDORES DOCKER ----
echo ""
echo "🐳 Estado de contenedores Docker:"
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" \
    2>/dev/null || echo "   Docker no disponible"

# ---- CONTENEDORES CAÍDOS ----
CAIDOS=$(sudo docker ps -a \
    --filter "status=exited" \
    --format "{{.Names}}" 2>/dev/null)
if [[ -n "$CAIDOS" ]]; then
    echo ""
    echo "⚠ Contenedores detenidos:"
    echo "$CAIDOS" | while read nombre; do
        echo "   - $nombre"
        log "ALERTA: Contenedor detenido: $nombre"
    done
fi

# ---- RAID ----
echo ""
echo "💿 Estado del RAID:"
cat /proc/mdstat | grep -E "md|active|blocks"

# ---- LVM ----
echo ""
echo "📦 Volúmenes LVM montados:"
df -h | grep "/data"

# ---- FIREWALL ----
echo ""
echo "🔒 Reglas de firewall activas:"
sudo iptables -L INPUT --line-numbers -n | head -8

# ---- SERVICIOS DEL SISTEMA ----
echo ""
echo "⚙️  Servicios del sistema:"
for servicio in ssh docker; do
    estado=$(systemctl is-active $servicio 2>/dev/null)
    if [[ "$estado" == "active" ]]; then
        echo "   ✓ $servicio: activo"
    else
        echo "   ✗ $servicio: inactivo"
        log "ALERTA: Servicio $servicio inactivo"
    fi
done

separador
log "Monitoreo ejecutado: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "Log guardado en: $LOG_FILE"
