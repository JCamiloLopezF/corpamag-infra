#!/bin/bash
# ============================================================
# Script: reporte_sistema.sh
# Descripción: Reporte completo del sistema CORPAMAG
# Usa: top, htop, journalctl, docker stats
# Autor: Juan Camilo Lopez
# ============================================================

LOG_DIR="/var/log/corpamag"
FECHA=$(date +"%Y%m%d_%H%M%S")
REPORTE="$LOG_DIR/reporte_$FECHA.txt"

mkdir -p "$LOG_DIR"

separador() {
    echo "==================================================" \
        | tee -a "$REPORTE"
}

titulo() {
    echo "" | tee -a "$REPORTE"
    separador
    echo "  $1" | tee -a "$REPORTE"
    separador
}

# ---- CABECERA ----
clear
echo "=================================================="  \
    | tee "$REPORTE"
echo "   REPORTE DE SISTEMA - CORPAMAG"                   \
    | tee -a "$REPORTE"
echo "   Fecha: $(date '+%Y-%m-%d %H:%M:%S')"            \
    | tee -a "$REPORTE"
echo "   Host: $(hostname)"                               \
    | tee -a "$REPORTE"
echo "==================================================" \
    | tee -a "$REPORTE"

# ---- INFORMACIÓN DEL SISTEMA ----
titulo "1. INFORMACIÓN DEL SISTEMA"
echo "OS: $(lsb_release -d | cut -f2)" | tee -a "$REPORTE"
echo "Kernel: $(uname -r)" | tee -a "$REPORTE"
echo "Uptime: $(uptime -p)" | tee -a "$REPORTE"
echo "Usuarios conectados: $(who | wc -l)" | tee -a "$REPORTE"

# ---- CPU ----
titulo "2. USO DE CPU (top)"
top -bn1 | head -5 | tee -a "$REPORTE"

# ---- MEMORIA RAM ----
titulo "3. USO DE MEMORIA RAM"
free -h | tee -a "$REPORTE"

# ---- DISCO ----
titulo "4. USO DE DISCO"
df -h | grep -E "^/dev/|Filesystem" | tee -a "$REPORTE"

# ---- PROCESOS MÁS PESADOS ----
titulo "5. TOP 5 PROCESOS POR CPU"
ps aux --sort=-%cpu | head -6 | tee -a "$REPORTE"

titulo "6. TOP 5 PROCESOS POR MEMORIA"
ps aux --sort=-%mem | head -6 | tee -a "$REPORTE"

# ---- CONTENEDORES DOCKER ----
titulo "7. ESTADO CONTENEDORES DOCKER"
sudo docker ps --format \
    "table {{.Names}}\t{{.Status}}\t{{.Ports}}" \
    | tee -a "$REPORTE"

# ---- ESTADÍSTICAS DOCKER ----
titulo "8. RECURSOS POR CONTENEDOR (docker stats)"
sudo docker stats --no-stream --format \
    "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" \
    | tee -a "$REPORTE"

# ---- RAID ----
titulo "9. ESTADO DEL RAID"
cat /proc/mdstat | tee -a "$REPORTE"

# ---- LVM ----
titulo "10. VOLÚMENES LVM"
df -h | grep "/data" | tee -a "$REPORTE"

# ---- FIREWALL ----
titulo "11. REGLAS DE FIREWALL ACTIVAS"
sudo iptables -L INPUT -n --line-numbers | tee -a "$REPORTE"

# ---- LOGS DEL SISTEMA ----
titulo "12. ÚLTIMOS EVENTOS DEL SISTEMA (journalctl)"
sudo journalctl -n 15 --no-pager \
    --output=short | tee -a "$REPORTE"

# ---- LOGS DE DOCKER ----
titulo "13. LOGS RECIENTES DE CONTENEDORES"
for contenedor in corpamag-web corpamag-db corpamag-ssh; do
    echo "" | tee -a "$REPORTE"
    echo "--- $contenedor ---" | tee -a "$REPORTE"
    sudo docker logs "$contenedor" \
        --tail 5 2>&1 | tee -a "$REPORTE"
done

# ---- CONECTIVIDAD ----
titulo "14. VERIFICACIÓN DE PUERTOS ACTIVOS"
ss -tlnp | grep -E "80|443|2222|5432|445|123" \
    | tee -a "$REPORTE"

# ---- PIE ----
separador
echo "  Reporte guardado en: $REPORTE" | tee -a "$REPORTE"
separador
