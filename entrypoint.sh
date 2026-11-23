#!/bin/sh
set -e

P="${PORT:-8000}"
X="${XPORT:-10001}"

# 根文件系统只读，运行期配置全部写到 /tmp
sed -e "s/__PORT__/$P/g" -e "s/__XPORT__/$X/g" /opt/tpl/nginx.conf.tpl > /tmp/nginx.conf
sed -e "s/\"port\": 10001/\"port\": $X/" /etc/xray/config.json > /tmp/xray.json

# nginx 会以 uid 100 运行，临时目录必须可写（容器在 userns 里，chown 会 EPERM）
mkdir -p /tmp/ngx-body /tmp/ngx-proxy /tmp/ngx-fastcgi /tmp/ngx-uwsgi /tmp/ngx-scgi
chmod 777 /tmp /tmp/ngx-body /tmp/ngx-proxy /tmp/ngx-fastcgi /tmp/ngx-uwsgi /tmp/ngx-scgi
chmod 644 /tmp/nginx.conf

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

# 非 root 跑 nginx：master 不以 root 运行时就不会去 chown 临时目录
exec su-exec 100:100 nginx -c /tmp/nginx.conf -g "daemon off;"
