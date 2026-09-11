# Clash Verge 直连规则 & 校园网 DNS 修复

一组用于 **Clash Verge (Rev)** 的 **Merge / Rules 增强模板**，解决两个实际问题：

1. **国内域名直连** —— 让 SUSTech、微信、知乎、Bilibili 等常见国内域名
   不经中转/代理。
2. **校园内网 DNS 修复** —— 修复 **TUN + fake-ip** 模式下，校内域名
   （`*.sustech.edu.cn` 等）被解析成假 IP（`198.18.x.x`）、导致无法访问
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

## 安全说明

- 本仓库**只包含规则与 DNS 模板**，不包含订阅链接、节点密码、token。
- `.gitignore` 已排除 `clash-verge.yaml`、`config.yaml`、`profiles.yaml` 等
  含敏感信息的运行时文件。请勿强制提交这些文件。

## License

MIT
