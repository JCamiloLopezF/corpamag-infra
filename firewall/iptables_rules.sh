#!/bin/bash
# ============================================================
# Script: iptables_rules.sh
# Descripción: Reglas de firewall para CORPAMAG
# Autor: Juan Camilo Lopez
# ============================================================

set -e

echo "=============================================="
echo "  Configurando Firewall CORPAMAG - iptables"
echo "=============================================="

# -------------------------------------------------------
# PASO 1: Limpiar reglas existentes
# -------------------------------------------------------
echo "[1/5] Limpiando reglas existentes..."
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X
echo "✓ Reglas limpiadas"

# -------------------------------------------------------
# PASO 2: Política por defecto - DENEGAR TODO
# -------------------------------------------------------
echo "[2/5] Aplicando política por defecto (DROP)..."
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT
echo "✓ Política DROP aplicada"

# -------------------------------------------------------
# PASO 3: Reglas básicas necesarias
# -------------------------------------------------------
echo "[3/5] Aplicando reglas básicas..."

# Permitir loopback (comunicación interna del sistema)
sudo iptables -A INPUT -i lo -j ACCEPT

# Permitir conexiones ya establecidas
sudo iptables -A INPUT -m state \
    --state ESTABLISHED,RELATED -j ACCEPT

echo "✓ Reglas básicas aplicadas"

# -------------------------------------------------------
# PASO 4: Reglas por servicio
# -------------------------------------------------------
echo "[4/5] Aplicando reglas por servicio..."

# SSH: puerto 2222 (acceso remoto seguro)
sudo iptables -A INPUT -p tcp --dport 2222 -j ACCEPT
echo "  ✓ SSH (2222) permitido"

# HTTP: portal web CORPAMAG
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
echo "  ✓ HTTP (80) permitido"

# HTTPS: portal web seguro
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
echo "  ✓ HTTPS (443) permitido"

# PostgreSQL: solo red interna Docker
sudo iptables -A INPUT -p tcp --dport 5432 \
    -s 172.0.0.0/8 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 5432 -j DROP
echo "  ✓ PostgreSQL (5432) solo red interna"

# Samba: archivos compartidos
sudo iptables -A INPUT -p tcp --dport 445 -j ACCEPT
echo "  ✓ Samba (445) permitido"

# NTP: sincronización horaria
sudo iptables -A INPUT -p udp --dport 123 -j ACCEPT
echo "  ✓ NTP (123/udp) permitido"

# ICMP: permitir ping desde red interna
sudo iptables -A INPUT -p icmp \
    --icmp-type echo-request -j ACCEPT
echo "  ✓ ICMP (ping) permitido"

# -------------------------------------------------------
# PASO 5: Log de paquetes rechazados
# -------------------------------------------------------
echo "[5/5] Configurando log de paquetes rechazados..."
sudo iptables -A INPUT -j LOG \
    --log-prefix "CORPAMAG-FIREWALL-DROP: " \
    --log-level 4
sudo iptables -A INPUT -j DROP
echo "✓ Log configurado"

# -------------------------------------------------------
# Guardar reglas permanentemente
# -------------------------------------------------------
echo ""
echo "Guardando reglas..."
sudo apt-get install -y iptables-persistent -qq
sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
echo "✓ Reglas guardadas en /etc/iptables/rules.v4"

echo ""
echo "=============================================="
echo "✓ Firewall CORPAMAG configurado exitosamente"
echo "=============================================="
echo ""
echo "Reglas activas:"
sudo iptables -L -n -v
