#!/bin/sh
set -e

P="${PORT:-8000}"
X="${XPORT:-10001}"

# 根文件系统只读，运行期配置全部写到 /tmp
sed -e "s/__PORT__/$P/g" -e "s/__XPORT__/$X/g" /opt/tpl/nginx.conf.tpl > /tmp/nginx.conf
sed -e "s/\"port\": 10001/\"port\": $X/" /etc/xray/config.json > /tmp/xray.json

/usr/bin/xray -config /tmp/xray.json &

# 等 xray 监听端口，再让 nginx 接客
i=0
while [ $i -lt 10 ]; do
    if nc -z 127.0.0.1 "$X" 2>/dev/null; then
        break
    fi
    i=$((i + 1))
    sleep 1
done

exec nginx -c /tmp/nginx.conf -g "daemon off;"
