FROM ubuntu:22.04
LABEL description="Servidor de archivos CORPAMAG - Samba"

RUN apt-get update && apt-get install -y \
    samba \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /srv/samba/documentos \
    && chmod 777 /srv/samba/documentos

COPY smb.conf /etc/samba/smb.conf

EXPOSE 445 139

CMD ["smbd", "--foreground", "--no-process-group"]
