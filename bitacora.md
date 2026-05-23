## Punto 2 — Servicios con Docker
**Fecha:** 22/05/2026

**Servicios implementados:**
- Nginx: portal web institucional CORPAMAG (puerto 80)
- PostgreSQL: base de datos de licencias ambientales (puerto 5432)
- OpenSSH: acceso remoto seguro (puerto 2222)
- Chrony: sincronización NTP (puerto 123)
- Samba: servidor de archivos compartidos (puerto 445)

**Problemas encontrados:**
1. `docker compose build` no funcionaba
   → Solución: usar `docker-compose build` (versión antigua)
2. Sin internet en la VM
   → Solución: cambiar red de UTM a Shared Network
3. Puertos 80 y 445 ocupados por Apache y Samba del sistema
   → Solución: `systemctl stop apache2` y `systemctl stop smbd`
4. `smbclient` no disponible dentro del contenedor
   → Solución: verificar desde el sistema host

**Resultado:** 5 contenedores activos y verificados exitosamente.

## Punto 4 — RAID y LVM
**Fecha:** 23/05/2026

**Implementación:**
- RAID 1 (espejo) simulado con loop devices sobre archivos 
  de 512MB en /opt/corpamag-discos/
- Volume Group: corpamag-vg sobre /dev/md0
- 3 Logical Volumes creados y montados:
  - lv-database → /data/database (150MB) - Para PostgreSQL
  - lv-archivos → /data/archivos (200MB) - Para Samba
  - lv-backups  → /data/backups (100MB)  - Para backups

**Justificación técnica:**
- RAID 1 protege contra pérdida de datos de licencias 
  ambientales ante fallo de disco
- LVM permite redimensionar volúmenes sin detener servicios

**Problemas encontrados:**
1. /tmp estaba al 100% de capacidad
   → Solución: cambiar ruta de discos simulados a /opt/
2. mdadm no estaba instalado
   → Solución: apt-get install -y mdadm lvm2

**Resultado:** RAID 1 activo, 3 LVs montados y verificados.
