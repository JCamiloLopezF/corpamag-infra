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


## Punto 5 — Seguridad
**Fecha:** 23/05/2026

**Firewall (iptables):**
- Política por defecto: DROP en INPUT y FORWARD
- Puertos permitidos: 80, 443, 2222, 445, 123/udp
- PostgreSQL (5432) restringido solo a red interna Docker
- Log de paquetes rechazados activo
- Reglas guardadas permanentemente en /etc/iptables/rules.v4

**Usuarios y grupos creados:**
- admin_ti → grupo corpamag_admins (sudo)
- func_ambiental → grupo corpamag_funcionarios
- auditor → grupo corpamag_readonly

**Permisos especiales aplicados:**
- STICKY BIT en /srv/corpamag/compartido (drwxrwxrwt)
  → Usuarios no pueden borrar archivos de otros
- SETGID en /srv/corpamag/documentos (drwxrws---)
  → Archivos nuevos heredan grupo corpamag_funcionarios
- SETUID en backup_runner.sh (-rwsr-x---)
  → Se ejecuta con privilegios de root

**Problemas encontrados:**
1. ls -l sobre archivo SETUID denegaba permiso
   → Solución: usar sudo ls -l

**Resultado:** Firewall activo y permisos especiales 
verificados exitosamente.

## Punto 6 — Scripts Bash
**Fecha:** 26/05/2026

**Scripts creados:**
- backup.sh: respalda BD PostgreSQL, documentos y 
  configuraciones Docker en /data/backups/
  Retención: 7 días, limpieza automática
- monitor.sh: verifica CPU, RAM, disco, contenedores
  Docker, RAID, LVM y firewall
- deploy.sh: despliegue completo automatizado de toda
  la infraestructura CORPAMAG

**Automatización con cron:**
- Monitoreo: cada 5 minutos
- Backup: diario a las 2:00 AM

**Archivos de backup generados:**
- db_backup_20260526_190605.sql (5.2KB)
- docker-compose_20260526_190605.yml (3.4KB)
- docs_backup_20260526_190605.tar.gz (145B)

**Resultado:** 3 scripts operativos y cron configurado.

## Punto 7 — Monitoreo básico
**Fecha:** 26/05/2026

**Herramientas utilizadas:**
- top: monitoreo de procesos en tiempo real
- htop: versión mejorada, instalada y verificada
- journalctl: logs del sistema y servicios Docker
- docker logs: logs individuales por contenedor
- docker stats: recursos por contenedor en tiempo real

**Script reporte_sistema.sh creado:**
- Genera reporte completo en /var/log/corpamag/
- Secciones: CPU, RAM, disco, contenedores Docker,
  RAID, LVM, firewall y logs del sistema
- Automatizado con cron cada 5 minutos

**Problemas encontrados:**
1. Intento de agregar Prometheus y Grafana
   → Error: incompatibilidad de docker-compose 1.29.2
   con imágenes recientes (KeyError: ContainerConfig)
   → Solución: se omitieron por ser opcionales

2. web-server aparecía como unhealthy
   → Causa: healthcheck con wget no compatible con
   la versión de nginx:alpine
   → Intento de fix con --force-recreate falló por
   mismo bug de docker-compose 1.29.2
   → Solución final: eliminar healthchecks del
   docker-compose.yml y reconstruir con:
   docker system prune -af && docker-compose up -d

3. docker volume prune eliminó volúmenes
   → Se reconstruyeron automáticamente al hacer
   docker-compose up -d

**Resultado:** 5 contenedores operativos sin errores,
monitoreo funcional con herramientas nativas.
