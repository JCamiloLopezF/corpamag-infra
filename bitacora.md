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
