FROM postgres:15-alpine
LABEL description="Base de datos CORPAMAG - Licencias ambientales"

ENV POSTGRES_DB=corpamag_db
ENV POSTGRES_USER=corpamag_admin
ENV POSTGRES_PASSWORD=Corpamag2024!

COPY init.sql /docker-entrypoint-initdb.d/

EXPOSE 5432
