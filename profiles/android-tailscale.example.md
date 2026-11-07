# Android 上使用 CMFA 访问 Tailscale 服务

本示例适用于官方 Clash Meta for Android 2.11.32.Meta 的源码构建：该版本使用的 Mihomo 内核包含 Tailscale 出站，并支持 `ts://` DNS。手机安装包的来源和实际运行情况仍需在设备上确认。Android 同一用户配置通常只能运行一个 VPN 服务；先断开官方 Tailscale App，再启动 CMFA 的 VPN。CMFA 内置的 Tailscale 出站会作为一个独立设备加入同一个 tailnet。

以下是需要合并进现有配置的片段，并非完整配置。先复制或备份当前配置，通过客户端支持的本地配置编辑或覆写方式添加；保留已有节点、DNS 和规则，不要在同一个 YAML 映射中创建重复的 `proxies`、`dns`、`nameserver-policy` 或 `rules` 键。订阅更新可能覆盖直接编辑的配置，应确认实际生效的配置。

将下面节点添加到已有 `proxies` 列表；节点名称须唯一。无需填写 `auth-key`：

```yaml
- name: ts-board
  type: tailscale
  hostname: cmfa-board
```

将下面一项合并到已有 `dns.nameserver-policy`，把 `board.example.ts.net` 替换为服务的真实完整域名：

```yaml
board.example.ts.net: ts://ts-board
```

此策略需要 Mihomo DNS 在实际生效配置中启用；当 `dns.enable: false` 时使用系统 DNS，策略不会生效。浏览器的安全 DNS 或应用自己的加密 DNS 也可能绕过这一策略。请先检查当前配置及连接命中情况，保留已有 DNS 设置。

将下面规则添加到已有 `rules` 列表前部，放在会先匹配该域名的规则以及 `MATCH` 之前：

```yaml
- DOMAIN,board.example.ts.net,ts-board
```

如果当前 DNS 使用 `fake-ip`，并且 `fake-ip-filter-mode` 为 `blacklist` 或未指定，可按需将目标完整域名添加到已有 `dns.fake-ip-filter` 列表，使该域名使用真实解析结果。已有列表和模式应保持原样；如果模式为 `whitelist`，不要照搬这一项，应先核对现有过滤策略。

```yaml
- board.example.ts.net
```

启用配置后，用浏览器访问该服务的 HTTPS 完整域名，首次连接会触发出站启动，可能超时。打开 CMFA 日志，在手机本机找到 Tailscale 输出的交互登录链接，使用同一个 Tailscale 账号完成授权，再重试访问。tailnet 如果要求管理员批准新设备，还需在 Tailscale 管理页面批准。浏览器应正常验证证书。在 CMFA 连接记录中检查目标连接是否命中 `ts-board`；如果客户端只能看到目标 IP 而无法识别域名，域名规则可能不会命中。确认服务可访问后，可重启 CMFA 并再次访问，检查状态是否保留。

登录链接、完整日志和 Tailscale 状态目录可能包含敏感信息，不要发到聊天或上传仓库。默认状态目录名为 `tailscale`；实际路径及更新、清除应用数据或卸载后的保留情况取决于客户端环境。若未出现登录链接或访问失败，先确认有效配置、日志级别、设备授权、DNS 策略和网络连通性；首次启动还需能够访问 Tailscale 控制服务。只分享不含链接、密钥和个人地址的错误类型。

参考：[CMFA 2.11.32 构建参数](https://github.com/MetaCubeX/ClashMetaForAndroid/blob/v2.11.32/core/build.gradle.kts)、[该版本内核的 Tailscale 出站](https://github.com/MetaCubeX/mihomo/blob/e26714a181ac0e2fa803453c0a8e9a9ce94e31cb/adapter/outbound/tailscale.go)、[该版本内核的 DNS 地址解析](https://github.com/MetaCubeX/mihomo/blob/e26714a181ac0e2fa803453c0a8e9a9ce94e31cb/config/config.go#L1174-L1179)、[Mihomo Tailscale 配置文档](https://wiki.metacubex.one/en/config/proxies/tailscale/)、[Android VPN 文档](https://developer.android.com/develop/connectivity/vpn)。
