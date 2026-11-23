# Clash Verge Rev 直连与 DNS 模板

为现有订阅补充直连规则，或修复 TUN 的 `fake-ip` 模式下校园网和私有网络的域名解析。先按场景选文件，再检查 Clash 实际加载的配置。

| 场景 | 使用的文件 | 配置位置 |
| --- | --- | --- |
| 常用国内域名和私有地址直连 | [通用直连规则](profiles/rules.sample.yaml) | 订阅的 Rules 扩展 |
| 校园网或学校 VPN 内访问南科大服务 | [校园 DNS 模板](profiles/merge-dns.sample.yaml) | 订阅的 Merge 扩展 |
| 校外或手机热点访问 BB、CAS | [校外 DNS 补丁](profiles/dns-overrides-sustech-offcampus.sample.yaml) | Clash Verge DNS 覆写 |
| 其他内网域名 | [通用私有 DNS 模板](profiles/merge-private-dns.sample.yaml) | 订阅的 Merge 扩展，按环境填写 DNS |
| 腾讯服务直连 | [腾讯直连脚本](profiles/tencent-direct.js)、[DNS 示例](profiles/dns-settings-tencent.sample.yaml) | 全局扩展脚本和实际生效的 DNS 设置 |
| 桌面 Tailscale MagicDNS | [Tailscale 直连脚本](profiles/tailscale-direct.js) | 全局扩展脚本 |
| Android FlClash 内置 Tailscale | [FlClash 配置步骤](profiles/android-flclash-tailscale.md) | 订阅的脚本扩展 |

## 应用并检查

1. 在 Clash Verge Rev 的订阅页面编辑目标订阅。将直连模板的条目合并到 Rules 的 `prepend`，并把 `<DIRECT_GROUP>` 替换为 `DIRECT` 或订阅里已有的直连组。
2. 将 DNS 模板的条目并入实际使用的 DNS 配置。Clash Verge Rev 2.5.5 起，扩展中写出的 `dns` 子字段按整个字段替换。编辑 `fake-ip-filter` 或 `nameserver-policy` 时，把仍需保留的原有条目一并写入。启用应用级 **DNS 覆写** 时，检查其中的设置是否覆盖了扩展生成的字段。
3. 重新激活订阅。打开运行时配置检查 `rules`、`dns.fake-ip-filter` 和 `dns.nameserver-policy`，然后在「连接」页核对目标域名是否命中预期规则。

## 校外访问 BB、CAS

校外补丁适用于 `fake-ip-filter-mode: blacklist`。将补丁里的三个南科大域名后缀追加到现有过滤列表，并将这三个后缀的 DNS 策略设为补丁中列出的 DoH。GUI 的域名服务器策略格式为 `domain=server1;server2`，多条用逗号分隔。保留其他域名策略。

手机热点上的已有验证中，修正 DNS 后，访问 `https://bb.sustech.edu.cn/` 能跳转并显示 CAS 登录页。校内专用服务仍需校园网络或学校 VPN，校园模板中的 `system` 依赖当前设备的系统 DNS。

## Tailscale 与其他扩展

桌面脚本依赖已连接的 Tailscale 和 MagicDNS，通过 Quad100 解析 `ts.net`。已有全局脚本时，把 `applyTailscaleDirect` 函数合并进现有脚本，在现有 `main` 的返回处调用它。检查实际生效的 DNS，尤其是启用了 DNS 覆写或指定了 `direct-nameserver` 的情况。腾讯脚本里的 fake-IP 排除项按 `blacklist` 编写，其他过滤模式需要先调整条目格式。

另有针对特定订阅的 [CordCloud 规则](profiles/rules.cordcloud.yaml)、[xmrth 规则](profiles/rules.xmrth.yaml) 和 [Windows 重建脚本](scripts/rebuild.ps1)。运行重建脚本前，先核对脚本顶部的安装和订阅路径。

参考 [Clash Verge Rev 扩展文档](https://www.clashverge.dev/guide/extend.html) 与 [mihomo DNS 文档](https://wiki.metacubex.one/en/config/dns/)。

规则参考 [MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat)、[Loyalsoldier/clash-rules](https://github.com/Loyalsoldier/clash-rules) 和 [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script)。仓库按 MIT 许可发布。
