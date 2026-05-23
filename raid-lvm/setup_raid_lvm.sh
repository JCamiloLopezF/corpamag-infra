#!/bin/bash
# ============================================================
# Script: setup_raid_lvm.sh
# Descripción: Configuración RAID 1 + LVM para CORPAMAG
# Nota: RAID simulado con loop devices (sin discos físicos extra)
# Autor: Juan Camilo Lopez
# ============================================================

set -e

echo "=============================================="
echo "  Configuración RAID 1 + LVM - CORPAMAG"
echo "=============================================="

# -------------------------------------------------------
# PASO 1: Crear archivos que simulan discos físicos
# Cada archivo de 512MB simula un disco
# -------------------------------------------------------
echo "[1/6] Creando discos simulados..."
mkdir -p /opt/corpamag-discos

dd if=/dev/zero of=/opt/corpamag-discos/disco1.img bs=1M count=512 status=progress
dd if=/dev/zero of=/opt/corpamag-discos/disco2.img bs=1M count=512 status=progress

echo "✓ Discos simulados creados"

# -------------------------------------------------------
# PASO 2: Asociar archivos a dispositivos loop
# -------------------------------------------------------
echo "[2/6] Configurando loop devices..."

LOOP1=$(sudo losetup -f --show /opt/corpamag-discos/disco1.img)
LOOP2=$(sudo losetup -f --show /opt/corpamag-discos/disco2.img)

echo "✓ Loop device 1: $LOOP1"
echo "✓ Loop device 2: $LOOP2"

# -------------------------------------------------------
# PASO 3: Crear RAID 1 (espejo) con los loop devices
# -------------------------------------------------------
echo "[3/6] Creando RAID 1..."

sudo mdadm --create /dev/md0 \
    --verbose \
    --level=1 \
    --raid-devices=2 \
    --force \
    "$LOOP1" "$LOOP2"

echo "✓ RAID 1 creado en /dev/md0"
sleep 3
cat /proc/mdstat

# -------------------------------------------------------
# PASO 4: Crear Physical Volume LVM sobre el RAID
# -------------------------------------------------------
echo "[4/6] Creando Physical Volume..."
sudo pvcreate /dev/md0
sudo pvdisplay /dev/md0

# -------------------------------------------------------
# PASO 5: Crear Volume Group
# -------------------------------------------------------
echo "[5/6] Creando Volume Group: corpamag-vg..."
sudo vgcreate corpamag-vg /dev/md0
sudo vgdisplay corpamag-vg

# -------------------------------------------------------
# PASO 6: Crear Logical Volumes
# -------------------------------------------------------
echo "[6/6] Creando Logical Volumes..."

# LV para base de datos (150MB)
sudo lvcreate -L 150M -n lv-database corpamag-vg

# LV para archivos compartidos (200MB)
sudo lvcreate -L 200M -n lv-archivos corpamag-vg

# LV para backups (100MB)
sudo lvcreate -L 100M -n lv-backups corpamag-vg

# Formatear con ext4
sudo mkfs.ext4 /dev/corpamag-vg/lv-database
sudo mkfs.ext4 /dev/corpamag-vg/lv-archivos
sudo mkfs.ext4 /dev/corpamag-vg/lv-backups

# Crear puntos de montaje
sudo mkdir -p /data/database /data/archivos /data/backups

# Montar los volúmenes
sudo mount /dev/corpamag-vg/lv-database /data/database
sudo mount /dev/corpamag-vg/lv-archivos /data/archivos
sudo mount /dev/corpamag-vg/lv-backups  /data/backups

echo ""
echo "=========================================="
echo "✓ RAID 1 + LVM configurado exitosamente"
echo "=========================================="
echo ""
echo "Estado RAID:"
cat /proc/mdstat
echo ""
echo "Logical Volumes:"
sudo lvdisplay
echo ""
echo "Montajes activos:"
df -h | grep /data
