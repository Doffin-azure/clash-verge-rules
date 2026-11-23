# Clash Verge Rev 直连与 DNS 模板

为现有订阅补充直连规则，或修复 TUN 的 `fake-ip` 模式下校园网和私有网络的域名解析。先按场景选文件，再检查 Clash 实际加载的配置。

| 场景 | 使用的文件 | 配置位置 |
| --- | --- | --- |
| 常用国内域名和私有地址直连 | [通用直连规则](profiles/rules.sample.yaml) | 订阅的 Rules 扩展 |
| 校园网或学校 VPN 内访问南科大服务 | [校园 DNS 模板](profiles/merge-dns.sample.yaml) | 订阅的 Merge 扩展 |
| 校外或手机热点访问 BB、CAS | [校园 DNS 使用说明](profiles/sustech-dns.md) | Clash Verge DNS 覆写 |
| 其他内网域名 | [通用私有 DNS 模板](profiles/merge-private-dns.sample.yaml) | 订阅的 Merge 扩展，按环境填写 DNS |
| 腾讯服务直连 | [腾讯直连脚本](profiles/tencent-direct.js)、[DNS 示例](profiles/dns-settings-tencent.sample.yaml) | 全局扩展脚本和实际生效的 DNS 设置 |
| 桌面 Tailscale MagicDNS | [Tailscale 配置说明](profiles/tailscale-direct.md) | 全局扩展脚本 |
| Android FlClash 内置 Tailscale | [FlClash 配置步骤](profiles/android-flclash-tailscale.md) | 订阅的脚本扩展 |

## 应用并检查

1. 在 Clash Verge Rev 的订阅页面编辑目标订阅。将直连模板的条目合并到 Rules 的 `prepend`，并把 `<DIRECT_GROUP>` 替换为 `DIRECT` 或订阅里已有的直连组。
2. 将 DNS 模板的条目并入实际使用的 DNS 配置。Clash Verge Rev 2.5.5 起，扩展中写出的 `dns` 子字段按整个字段替换。编辑 `fake-ip-filter` 或 `nameserver-policy` 时，把仍需保留的原有条目一并写入。启用应用级 **DNS 覆写** 时，检查其中的设置是否覆盖了扩展生成的字段。
3. 重新激活订阅。打开运行时配置检查 `rules`、`dns.fake-ip-filter` 和 `dns.nameserver-policy`，然后在「连接」页核对目标域名是否命中预期规则。

针对特定订阅可使用 [CordCloud 规则](profiles/rules.cordcloud.yaml) 或 [xmrth 规则](profiles/rules.xmrth.yaml)。[Windows 重建脚本](scripts/rebuild.ps1) 接受 `-SubFile`、`-RulesTpl`、`-VergeDir` 和 `-MihomoPath`，将路径指向当前设备的订阅、模板、配置目录和可执行程序。

参考 [Clash Verge Rev 扩展文档](https://www.clashverge.dev/guide/extend.html) 与 [mihomo DNS 文档](https://wiki.metacubex.one/en/config/dns/)。

规则参考 [MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat)、[Loyalsoldier/clash-rules](https://github.com/Loyalsoldier/clash-rules) 和 [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script)。仓库按 MIT 许可发布。
