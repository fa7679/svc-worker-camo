FROM teddysun/xray:latest

RUN apk add --no-cache nginx sed netcat-openbsd

COPY config.json /etc/xray/config.json
COPY nginx.conf.tpl /opt/tpl/nginx.conf.tpl
COPY entrypoint.sh /entrypoint.sh
COPY web/ /var/www/html/

RUN chmod +x /entrypoint.sh && rm -f /etc/nginx/http.d/default.conf

ENV PORT=8000
EXPOSE 8000

CMD ["/entrypoint.sh"]
