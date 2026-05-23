FROM nginx:alpine
LABEL maintainer="Juan Camilo Lopez"
LABEL description="Servidor web institucional CORPAMAG"

COPY html/ /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
