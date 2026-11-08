# Android FlClash 订阅与 Tailscale 看板

此方案适用于 FlClash 0.9.3：使用远程链接订阅，在该配置上启用 `android-flclash-tailscale.js` 脚本覆写。脚本将指定看板域名的 DNS 查询和连接交给内置 Tailscale 出站，同时保留原有节点和规则。该示例只覆盖指定的看板域名，其他私有服务需要分别配置并验证。

1. 将脚本中的 `board.example.ts.net` 改为自己的看板完整域名。`ts-flclash-board` 是出站名称，`flclash-board` 是手机上新设备的名称；名称发生冲突时应先调整脚本。
2. 在 FlClash 中通过链接添加订阅，长按配置并选择「编辑」，打开「自动更新」并设置间隔，例如 1440 分钟。后台运行可能受到 Android 电池管理限制，自动更新的实际时间由系统调度。
3. 在「工具 → 进阶配置 → 脚本」通过文件导入脚本。长按订阅并选择「扩展」，将扩展模式选择为「脚本」，选中导入的脚本，再点击「立即应用」。
4. 检查 FlClash 全局 DNS 覆写设置，避免覆盖订阅脚本生成的 DNS 策略。脚本要求订阅包含规则列表；若原有 DNS 使用 fake-ip 白名单，脚本会停止并要求先核查该配置。
5. 启动 FlClash 后访问看板。首次连接会触发内置 Tailscale 登录；在应用日志中打开授权链接，使用已有 tailnet 的账号登录，并在页面点击连接设备。如果网络要求管理员批准设备，还需完成批准。授权链接应保留在设备上。
6. 确认 HTTPS 看板可访问、连接命中对应 Tailscale 出站后，手动更新一次订阅并重新访问看板，再重启应用验证授权和规则是否保留。只有完成这些检查，才能确认当前设备上的配置有效。

Android 同一用户通常只能同时运行一个 VPN 服务。切换到 FlClash 后，独立 Tailscale 应用和其他 VPN 客户端需要断开；保留原客户端配置可以在需要时切换回来。各个客户端的 Tailscale 设备身份互相独立。

FlClash 的 Tailscale 身份保存在应用数据中。订阅同步与普通应用重启不应要求重新授权；清除应用数据、卸载应用、设备授权过期或被管理员移除时，可能需要重新授权。应用重启后的首次访问可能需要等待内置节点连接，若页面超时可稍后刷新。

不要提交订阅链接、Tailscale 授权链接、密钥或状态目录。参考：[FlClash 官方发行版](https://github.com/chen08209/FlClash/releases)、[Mihomo Tailscale 出站](https://wiki.metacubex.one/config/proxies/tailscale/)。
