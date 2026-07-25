FROM nginx:1.30-alpine

RUN apk add --no-cache python3 bash

RUN mkdir -p /etc/nginx/conf.d/ /etc/nginx/server.d/ /etc/nginx/options.d/ /etc/nginx/html/ /etc/pki/nginx
COPY src/ /
RUN rm -f /etc/nginx/conf.d/default.conf \
    && chmod +x /docker/scripts/entrypoint.sh \
    && chown -R nginx:nginx /etc/nginx /etc/pki/nginx /var/cache/nginx /run

ENV NGINX_PROXY_VERSION= \
    NGINX_PROXY_PORT=8080 \
    NGINX_PROXY_ROOT=/etc/nginx/html/ \
    NGINX_PROXY_INDEX="index.htm index.html" \
    NGINX_PROXY_OPTIONS= \
    NGINX_PROXY_DAEMON=off \
    NGINX_PROXY_CHARSET=utf-8 \
    NGINX_PROXY_ACCESS_LOG=/dev/stdout \
    NGINX_PROXY_ERROR_LOG=/dev/stdout \
    NGINX_PROXY_WORKER_CONNECTIONS=4096 \
    NGINX_PROXY_ERROR_LOG_LEVEL=info \
    NGINX_PROXY_SERVER_NAME=_ \
    NGINX_PROXY_SECURITY_DEFAULT_DIR=/etc/pki/nginx \
    NGINX_PROXY_FRONTEND_LOCATION=/ \
    NGINX_PROXY_BACKEND_LOCATION=/api/ \
    NGINX_PROXY_BACKEND_PROXY_PASS=http://127.0.0.1:1

EXPOSE 8080
USER nginx
ENTRYPOINT ["/docker/scripts/entrypoint.sh"]
CMD ["nginx"]
