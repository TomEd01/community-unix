FROM nginx:1.27-alpine
RUN apk add --no-cache openssl
COPY deploy/nginx/http.conf /etc/nginx/edge/http.conf
COPY deploy/nginx/https.conf /etc/nginx/edge/https.conf
COPY deploy/nginx/start.sh /usr/local/bin/edge-start
ENTRYPOINT ["/bin/sh", "/usr/local/bin/edge-start"]
