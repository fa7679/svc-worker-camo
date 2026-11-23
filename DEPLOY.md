# svc-worker 部署记录（v2，带伪装站）

- 平台：Hostless 免费 PaaS，应用名 `svc-worker`，仓库 `fa7679/svc-worker-camo`（main）
- 公网域名：https://svc-worker.hostless.app （和旧节点同域名）
- 协议：VLESS + WebSocket + TLS，WS 路径 `/api/stream`
- UUID：`38af0302-9aed-48ed-8aa9-285d894855d0`
- 出口：Hetzner Helsinki, Finland（AS24940，65.109.105.199）
- 规格：0.1 vCPU / 256MB，1 副本，容器端口 8000，TCP 健康检查 10s
- 验证时间：2026-11-23 11:36，Google 204 + ipinfo 均通过

## 伪装结构

```
客户端 ──TLS──> hostless 边缘 ──> nginx(:$PORT) ──/api/stream──> xray(:10001)
                                   └─ 其它路径：静态落地页 Vertex API
```

- `/` → 静态站，标题 `Vertex API — Realtime data endpoints for builders`
- `/api/v1/ping`、`/api/v1/health` → 真能返回 JSON 的假接口
- 未知路径 → 统一的 404 页
- 深色/浅色都是纯白站点，无外链资源，扫不出破绽

## 客户端链接

```
vless://38af0302-9aed-48ed-8aa9-285d894855d0@svc-worker.hostless.app:443?encryption=none&security=tls&type=ws&path=%2Fapi%2Fstream&host=svc-worker.hostless.app&sni=svc-worker.hostless.app#Hostless兜底
```

| 项目 | 值 |
|---|---|
| 地址 | svc-worker.hostless.app |
| 端口 | 443 |
| 用户 ID | 38af0302-9aed-48ed-8aa9-285d894855d0 |
| 传输 | ws |
| 路径 | /api/stream |
| TLS SNI / Host | svc-worker.hostless.app |

## 踩坑记录（下次改这仓库必看）

1. **根文件系统只读**：容器里 `/etc` 写不进去，运行期生成的 nginx.conf / xray 配置必须写 `/tmp`，并用 `nginx -c /tmp/nginx.conf`。
2. **容器在 userns 里，切不了 uid**：`su-exec 100:100` 报 `setgroups EPERM`；nginx master 以 root 跑时会去 `chown` 临时目录也 EPERM。解法是配置里写 `user root;`，临时目录放 `/tmp` 并 777。
3. **容器端口是 8000**（平台注入 `PORT=8000`），entrypoint 必须读 `$PORT`，不能写死。
4. **push 不会自动触发部署**：仓库创建方式没接 webhook，需要用 API 手动触发：
   `POST https://api.hostless.cloud/v1/apps/svc-worker/deployments` body `{}`
5. **API 鉴权**：前端 token 在 localStorage 的 `accessToken`（JWT），请求头 `Authorization: Bearer <token>`。
6. 日志接口：`GET /v1/apps/svc-worker/logs`（运行日志）、`GET /v1/apps/svc-worker/deployments/{id}/logs`（构建日志）。

## 运维命令

```bash
# 查状态
curl -s -H "Authorization: Bearer $TOK" https://api.hostless.cloud/v1/apps/svc-worker
# 手动触发部署
curl -s -X POST -H "Authorization: Bearer $TOK" -H "content-type: application/json" \
     -d '{}' https://api.hostless.cloud/v1/apps/svc-worker/deployments
# 看日志
curl -s -H "Authorization: Bearer $TOK" https://api.hostless.cloud/v1/apps/svc-worker/logs
```

本地文件：`G:\记录\梯子&学习\自动优选\hostless-camo`

备注：免费层长时间无流量可能休眠，首次连接需等实例唤醒。
