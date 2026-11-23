#!/bin/sh
set -e

P="${PORT:-10000}"
X="${XPORT:-10001}"

sed -e "s/__PORT__/$P/g" -e "s/__XPORT__/$X/g" /etc/nginx/nginx.conf.tpl > /etc/nginx/nginx.conf
sed -e "s/\"port\": 10001/\"port\": $X/" /etc/xray/config.json > /etc/xray/config.run.json

/usr/bin/xray -config /etc/xray/config.run.json &

# 等 xray 起来再让 nginx 接客
for i in 1 2 3 4 5 6 7 8 9 10; do
    if netstat -lnt 2>/dev/null | grep -q ":$X " || nc -z 127.0.0.1 "$X" 2>/dev/null; then
        break
    fi
    sleep 1
done

exec nginx -g "daemon off;"
