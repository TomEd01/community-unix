#!/bin/sh
set -eu

cert=/etc/letsencrypt/live/community-unix/fullchain.pem
key=/etc/letsencrypt/live/community-unix/privkey.pem
cp /etc/nginx/edge/http.conf /etc/nginx/conf.d/default.conf

fingerprint() {
    sha256sum "$cert" "$key"
}

current=""
if [ -s "$cert" ] && [ -s "$key" ]; then
    cp /etc/nginx/edge/https.conf /etc/nginx/conf.d/https.conf
    current=$(fingerprint)
fi

nginx -t
nginx -g 'daemon off;' &
nginx_pid=$!
trap 'kill -QUIT "$nginx_pid"; wait "$nginx_pid"; exit' TERM INT

while kill -0 "$nginx_pid" 2>/dev/null; do
    if [ -s "$cert" ] && [ -s "$key" ]; then
        updated=$(fingerprint)
        if [ "$updated" != "$current" ]; then
            cp /etc/nginx/edge/https.conf /etc/nginx/conf.d/https.conf
            nginx -t
            nginx -s reload
            current=$updated
            echo "Loaded updated TLS certificate"
        fi
    fi
    sleep 60 &
    wait $!
done

wait "$nginx_pid"
