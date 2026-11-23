# 桌面 Tailscale 直连

[扩展脚本](tailscale-direct.js) 需要已连接的 Tailscale 和 MagicDNS，通过 Quad100 解析 `ts.net`。已有全局脚本时，把 `applyTailscaleDirect` 合并进去，在已有 `main` 的返回处调用它。

重新加载后检查运行时 DNS 和连线规则。启用了 DNS 覆写或配置了 `direct-nameserver` 时，确认实际生效的服务器仍能解析目标名称。[腾讯脚本](tencent-direct.js) 使用 `blacklist` 格式的 fake-IP 排除项，使用其他模式时需先调整格式。
