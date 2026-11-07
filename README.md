# Clash Verge 直连规则 & 校园网 DNS 修复

一组用于 **Clash Verge (Rev)** 的 **Merge / Rules 增强模板**，解决两个实际问题：

1. **国内域名直连** —— 让 微信、知乎、Bilibili 等常见国内域名
   不经中转/代理。
2. **校园内网 DNS 修复** —— 修复 **TUN + fake-ip** 模式下，校内域名
   被解析成假 IP（`198.18.x.x`）、导致无法访问
   校内系统（如 `https://tis.sustech.edu.cn/`）的问题。

> 模板以 Clash Verge 的 **Profile Enhancement（增强配置）** 形式工作：
> 以 `prepend` 注入规则、以 merge 设置 DNS，**不随机场订阅更新而失效**。

---

## 问题背景

### 问题 1：内网域名被 fake-ip 劫持

在 **TUN + fake-ip** 模式下，Clash 会把所有域名解析成 `198.18.x.x` 假 IP，
再由内核按规则分流。但校园内网服务的真实地址（如 `172.18.23.218`）
**只有校园网 DNS 才能解析**，公共 DNS（8.8.8.8 / DoH）解析不到。

结果：即使规则判定为「直连」，Clash 也拿不到内网 IP，页面自然打不开。

**修复思路**（借鉴 meta-rules-dat / Loyalsoldier）：

- 把内网/校园域名加入 `fake-ip-filter`，不做 fake-ip；
- 用 `nameserver-policy` 让这些域名走 `system`（校园网 DNS）。

### 问题 2：国内域名走了中转

部分订阅的默认规则会把国内域名也送进代理。通过 Rules 模板的 `prepend`
在**规则最前面**插入直连规则即可优先命中。

---

## 目录结构

```
clash-verge-rules/
├── README.md
├── .gitignore
└── profiles/
    ├── rules.sample.yaml            # 规则模板（通用，<DIRECT_GROUP> 占位）
    ├── rules.cordcloud.yaml         # CordCloud 版（直连组 🎯 全球直连）
    ├── rules.xmrth.yaml             # xmrth1.net 版（直连组 ❌不代理）
    ├── merge-dns.sample.yaml        # 校园网 DNS 修复（sustech 专用）
    ├── merge-dns.yaml               # 校园网 DNS 修复（CordCloud 版）
    └── merge-private-dns.sample.yaml# 内网/私有网络 DNS 修复（通用版）
```

---

## 使用方法

1. Clash Verge → **订阅（Profiles）**
2. 右键目标订阅 → **编辑规则 / 编辑 Merge**
3. 将本仓库对应文件的内容粘贴进去：
   - 直连规则 → 放进 **Rules 模板**（`prepend`）
   - DNS 修复 → 合并进 **Merge 模板**（`dns` 段）
4. 重新应用订阅 / 刷新配置
5. 验证：访问 `https://tis.sustech.edu.cn/` 应可正常打开

> `<DIRECT_GROUP>` 占位符替换规则：
> - 推荐直接写 `DIRECT`（固定直连，不受策略组手动选择影响）
> - 或填你订阅里的直连组名，如 `🎯 全球直连` / `❌不代理`

---

## 规则说明

### 私有网络 / 内网优先直连

规则最前面加入（借鉴 meta-rules-dat 与 Loyalsoldier 的做法）：

```yaml
- GEOIP,private,<DIRECT_GROUP>,no-resolve   # 10/8、172.16/12、192.168/16、169.254/16 等
- GEOIP,LAN,<DIRECT_GROUP>,no-resolve       # 局域网
- IP-CIDR,172.16.0.0/12,<DIRECT_GROUP>,no-resolve
```

`GEOIP,private` 是 mihomo 内置集合，覆盖所有保留地址段，比手写 CIDR 更全。
校园内网服务（`172.18.x.x`）由此自动直连。

### DNS 修复关键配置

```yaml
dns:
  fake-ip-filter:
    - '*.sustech.edu.cn'
    - '*.edu.cn'
  nameserver-policy:
    '+.sustech.edu.cn': system   # 用系统(校园网)DNS 解析
    '+.edu.cn': system
```

---

## 借鉴来源 / 参考资料

本项目规则在编写时参考了以下成熟项目的最佳实践：

- **[MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat)**
  —— mihomo 官方规则数据。借鉴了 `GEOIP,private,DIRECT,no-resolve`、
  `nameserver-policy` 按 `geosite` 分类指定 DNS 的写法。
- **[Loyalsoldier/clash-rules](https://github.com/Loyalsoldier/clash-rules)**
  —— 28k+ star 的 Clash 规则集。借鉴了 `RULE-SET,private,DIRECT` 的私有网络
  直连思路，以及规则集（rule-providers）的组织方式。
- **[blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script)**
  —— 通用直连域名列表 `Direct.list`，用于校对国内域名清单。
- **[Clash Verge Rev 官方文档](https://www.clashverge.dev/)**
  —— Merge / Rules 模板的 `prepend` / `append` / `delete` 语义。

### 可选：直接引用现成规则集（推荐进阶用户）

与其手工维护域名列表，可以直接用 `rule-providers` 引用上述项目：

```yaml
rule-providers:
  private:
    type: http
    behavior: domain
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/private.txt"
    path: ./ruleset/private.yaml
    interval: 86400
  cn:
    behavior: domain
    format: mrs
    type: http
    url: "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/cn.mrs"
    path: ./ruleset/cn.mrs
    interval: 86400

rules:
  - RULE-SET,private,DIRECT
  - GEOIP,private,DIRECT,no-resolve
  - GEOSITE,cn,DIRECT
  - GEOIP,CN,DIRECT
  - MATCH,PROXY
```

> 注意：`rule-providers` 需要网络能访问 raw.githubusercontent.com 或 jsdelivr。
> 手工列表（本项目模板）则无此依赖，离线也可用。

---

## 命令行重建（可选）

Clash Verge 只在 GUI 里「激活订阅」时才重新合并 Merge/Rules 模板，命令行无法
直接触发。`scripts/rebuild.ps1` 用**同样的合并语义**手动重建运行时配置，并
通过 mihomo 命名管道 reload，无需打开 GUI：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\rebuild.ps1
```

脚本流程：

1. 读取订阅原始文件 + Rules 模板 `prepend` 规则
2. 组装（模板规则在前，订阅规则去重在后）
3. 用 `verge-mihomo -t` 验证配置
4. 备份 `clash-verge.yaml` → `.rebuildbak`，写入并 reload

> 修改脚本顶部的「配置区」即可适配其它订阅（`SubFile` / `RulesTpl`）。
> 该脚本为 Windows PowerShell 5.1 设计，文件需保存为 **UTF-8 with BOM**。

## 安全说明

- 本仓库**只包含规则与 DNS 模板**，不包含订阅链接、节点密码、token。
- `.gitignore` 已排除 `clash-verge.yaml`、`config.yaml`、`profiles.yaml` 等
  含敏感信息的运行时文件。请勿强制提交这些文件。

## License

MIT


## 腾讯直连与 DNS 配置（2026-11）

- `profiles/tencent-direct.js` 是全局扩展脚本：将腾讯相关域名及 `GEOSITE,tencent` 放到规则前部并指定 `DIRECT`，同时尝试追加 fake-IP 排除项。
- `profiles/merge-dns.yaml` 是当前订阅的 Merge 模板，包含腾讯域名（包括 `cdn-go.cn`）使用 DNSPod 和阿里 DNS 的策略，并保留校园网域名使用系统 DNS 的策略。
- `profiles/dns-settings-tencent.sample.yaml` 是本机 DNS 设置的脱敏示例，包含腾讯域名的 fake-IP 排除项。启用 Clash Verge 的 DNS 设置时，DNS 设置可能覆盖扩展脚本或 Merge 中的 `fake-ip-filter`；请将这些排除项合并到实际生效的 DNS 设置中，保留原有条目，不要直接覆盖其他网络所需的配置。校园网域名也应按实际情况保留 fake-IP 排除项。

修改后在 Clash Verge 订阅页面重新激活当前订阅，检查运行时配置的 `dns.fake-ip-filter` 和 `dns.nameserver-policy`，并在连接页面确认 `git.code.tencent.com` 和 `cdn-go.cn` 命中直连。示例只包含规则与 DNS 配置，切勿提交订阅链接、节点配置、令牌或生成的完整运行时配置。

## Tailscale 与 Clash Verge

`profiles/tailscale-direct.js` 是可选的 Clash Verge Rev 扩展脚本，适用于已经安装并连接 Tailscale、启用 MagicDNS，且希望 Clash 将 Tailscale 域名交给本机系统路由的场景。它只添加以下通用配置：

- 在规则最前方放置 `DOMAIN-SUFFIX,ts.net,DIRECT`，以及 Tailscale 本机 DNS 服务 Quad100 的 `IP-CIDR,100.100.100.100/32,DIRECT,no-resolve`；不会自动加入整个 `100.64.0.0/10` 地址段。
- 若没有针对 `ts.net` 的现有精确或通配 DNS 策略，添加 `+.ts.net` → `100.100.100.100`。已有的 `ts.net`、`+.ts.net` 或 `*.ts.net` 策略会保留，需自行核实其上游是否能够解析目标名称。
- `fake-ip-filter-mode` 为默认的 `blacklist` 时，将 `+.ts.net` 加入过滤列表；为 `rule` 时，将 `DOMAIN-SUFFIX,ts.net,real-ip` 放在列表前部。`whitelist` 模式中匹配项反而会获得 fake-IP，脚本保留原列表，不自动添加或删除条目；如果已有宽泛匹配覆盖了目标域名，需要按实际配置手动调整并验证。

脚本不会启用 Tailscale、MagicDNS 或 Clash DNS，不会设置 TUN 路由、写入节点密钥，也不保证 `DIRECT` 一定能绕过操作系统或 TUN 的其他路由。它对 `ts.net` 使用 Quad100：Tailscale 未连接、MagicDNS 不可用或其他 DNS 策略更具体时，名称解析可能失败；这也可能影响通过公共网络访问的 `ts.net` 服务，请按实际需要选择是否启用。已有 `100.64.0.0/10` 网络也可能与 Tailscale 地址冲突，不能单靠此脚本解决。

### 与现有腾讯直连脚本共存

如果还没有自定义扩展脚本，可将 `tailscale-direct.js` 作为全局扩展脚本使用。已有 `tencent-direct.js` 或其他全局脚本时，不要覆盖它，也不要同时保留两个 `main` 入口：

仓库现有 `tencent-direct.js` 的 fake-IP 域名条目按 `blacklist` 语义编写。若实际模式为 `rule`，它直接追加的域名条目不符合规则格式；若为 `whitelist`，这些匹配项会得到 fake-IP。使用这两种模式时，应先分别适配并核验现有腾讯脚本，再合并 Tailscale 函数；本次 Tailscale 脚本不会修改腾讯脚本。

1. 将 `tailscale-direct.js` 中的 `applyTailscaleDirect` 函数复制到现有脚本中；不复制文件底部的 `main` 函数。
2. 保留现有 `main` 中全部逻辑，将其最后的 `return config;` 改为 `return applyTailscaleDirect(config);`。
3. 保存并重新应用目标订阅。现有全局脚本会先运行，Tailscale 函数最后把两条规则放到最前面。

Clash Verge 的订阅扩展和应用设置可能在全局脚本之后覆盖 DNS 字段；尤其在启用应用 DNS 设置时，检查**最终运行时配置**中的 `rules`、`dns.nameserver-policy` 和 `dns.fake-ip-filter`，不要只检查脚本内容。必要时在目标订阅的扩展脚本中合并相同辅助函数，同时保留原有订阅脚本。`dns.enable` 关闭或 `enhanced-mode` 为 `redir-host` 时，fake-IP 过滤不适用，脚本不会改变这两个设置。

如果配置了 `dns.direct-nameserver`，且 `direct-nameserver-follow-policy` 为 `false` 或未设置，DIRECT 出站重新解析域名时可能不遵循上面的 DNS 策略；请检查实际生效的解析方式。脚本不会自动更改这两个全局设置。

在设备上先确认 Tailscale 已连接，并能通过 Quad100 正确解析自己的 MagicDNS 名称，再查看 Clash「连接」是否命中预期的 DIRECT 规则。不同系统的 TUN、DNS 和路由行为可能不同；如果出现冲突，需要按设备核实实际连接，不能把静态配置校验视为端到端验证。

Android 的 Tailscale 与使用 VPN 模式的 Clash 客户端通常不能同时占用系统 VPN。可以参考 [Android 内置 Tailscale 出站示例](profiles/android-tailscale.example.md)，尝试由 Clash 加入同一个私有网络；示例仍需在具体设备上验证。本脚本不配置该出站，也不存储登录密钥或设备状态。

参考：[Clash Verge 扩展脚本及优先级](https://www.clashverge.dev/guide/extend.html)、[mihomo DNS 配置](https://wiki.metacubex.one/en/config/dns/)、[Tailscale Quad100](https://tailscale.com/docs/reference/quad100)、[Tailscale 与其他 VPN](https://tailscale.com/docs/reference/faq/other-vpns)、[mihomo Tailscale 出站](https://wiki.metacubex.one/en/config/proxies/tailscale/)。
