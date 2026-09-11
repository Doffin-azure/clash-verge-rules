# Clash Verge 直连规则 & 校园网 DNS 修复

Clash Verge (Rev) 的 **Merge / Rules 模板**，用于：

1. 让常见国内域名（SUSTech、微信、知乎、Bilibili 等）**直连**，不走中转。
2. 修复 **fake-ip 模式**下校园内网域名（`*.sustech.edu.cn` 等）解析成假 IP、
   导致无法访问校内服务（如 `tis.sustech.edu.cn`）的问题。

> 这些模板以 **Clash Verge 的 Profile Enhancement（增强配置）** 形式工作，
> 不随订阅更新失效：即使机场订阅刷新，自定义规则和 DNS 设置依然保留。

## 目录结构

```
clash-verge-rules/
├── README.md
├── .gitignore
└── profiles/
    ├── rules.sample.yaml        # 规则模板样例（直连组名可改）
    ├── merge-dns.sample.yaml    # DNS merge 模板样例
    ├── rules.❌不代理.yaml       # xmrth1.net 订阅用（直连组 ❌不代理）
    └── merge-dns.yaml           # CordCloud 订阅用（直连组 🎯 全球直连）
```

## 原理

### 1. 域名直连（Rules 模板）

Clash Verge 的 "Rules 模板" 支持 `prepend` / `append` / `delete`：
`prepend` 的规则会插入到订阅规则**最前面**，因此优先命中。

```yaml
prepend:
  - DOMAIN-SUFFIX,sustech.edu.cn,🎯 全球直连
  - DOMAIN-SUFFIX,zhihu.com,🎯 全球直连
  - DOMAIN-SUFFIX,bilibili.com,🎯 全球直连
  # ...
```

`🎯 全球直连` 需替换为你订阅里实际的"直连策略组"名称，
或直接写 `DIRECT`。

### 2. 校园网 DNS 修复（Merge 模板）

在 **TUN + fake-ip** 模式下，Clash 会把所有域名解析成 `198.18.x.x` 假 IP。
但校园内网服务（`172.18.x.x`）只有**校园网 DNS** 能解析。若 Clash 用公共 DNS
（8.8.8.8 / DoH）去解析，就永远拿不到内网地址。

修复方法：

```yaml
dns:
  fake-ip-filter:          # 这些域名不做 fake-ip
    - '*.sustech.edu.cn'
    - '*.edu.cn'
  nameserver-policy:       # 这些域名用系统(校园网)DNS 解析
    '+.sustech.edu.cn': system
    '+.edu.cn': system
```

`system` 表示使用操作系统当前配置的 DNS（校园网下发的服务器）。

> ⚠️ 部分 Clash Verge 版本对 `fake-ip-filter` 是**替换**语义。
> 若发现原有 `.lan/.local` 等条目丢失，请把完整列表写全（见
> `merge-dns.sample.yaml` 中的完整写法）。

## 使用方法

1. Clash Verge → **订阅**（Profiles）
2. 右键目标订阅 → **编辑规则 / 编辑 Merge**
   （或 **编辑文件** 后把内容粘贴进去）
3. 把本仓库对应文件内容贴入，保存
4. 点击订阅卡片重新应用，或刷新配置
5. 验证：访问 `https://tis.sustech.edu.cn` 应正常打开

## 验证

Windows PowerShell 可通过 mihomo 命名管道查询实际匹配规则：

```powershell
# 见 scripts/verify.ps1（可选）
```

或直接在 Clash Verge → **连接** 页面查看每条连接的 Rule / Proxy 列。

## 安全说明

- 本仓库**只包含规则与 DNS 模板**，不包含订阅链接、节点密码、token。
- 请勿提交 `clash-verge.yaml` / `config.yaml` 等含敏感信息的运行时文件
  （`.gitignore` 已做基础防护）。

## License

MIT
