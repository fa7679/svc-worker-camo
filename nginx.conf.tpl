worker_processes 1;
error_log /dev/stderr warn;
pid /tmp/nginx.pid;

events {
    worker_connections 512;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    access_log /dev/stdout;
    sendfile on;
    server_tokens off;

    client_body_temp_path /tmp/ngx-body;
    proxy_temp_path       /tmp/ngx-proxy;
    fastcgi_temp_path     /tmp/ngx-fastcgi;
    uwsgi_temp_path       /tmp/ngx-uwsgi;
    scgi_temp_path        /tmp/ngx-scgi;

    server {
        listen __PORT__;
        server_name _;

        root /var/www/html;
        index index.html;

        client_max_body_size 8m;

        location = /api/stream {
            proxy_pass http://127.0.0.1:__XPORT__;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_buffering off;
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
        }

        # 伪装：一个能真跑通的 JSON 接口，让站点看起来确实是个 API 服务
        location = /api/v1/ping {
            default_type application/json;
            add_header Cache-Control "no-store";
            return 200 '{"ok":true,"region":"eu-north","latency_ms":12}';
        }

        location = /api/v1/health {
            default_type application/json;
            add_header Cache-Control "no-store";
            return 200 '{"status":"operational","uptime_s":86400}';
        }

        location / {
            try_files $uri $uri/ =404;
        }

        error_page 404 /404.html;
        location = /404.html {
            internal;
        }
    }
}
