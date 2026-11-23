# 南科大 DNS 配置

校园网或学校 VPN 上使用 [校园 DNS 模板](merge-dns.sample.yaml)。其中的 `system` 取决于设备当前的 DNS。

校外或手机热点访问 BB、CAS 时，使用 [校外 DNS 补丁](dns-overrides-sustech-offcampus.sample.yaml)。在 Clash Verge DNS 覆写中确认过滤模式为 `blacklist`，把三个域名后缀追加到过滤列表，并为这些后缀使用补丁里的 DoH。配置框使用 `domain=server1;server2`，多项用逗号分隔。保留其他域名的策略。

重新加载后访问 `https://bb.sustech.edu.cn/`，核对能否到达 CAS 登录页。校内专用服务继续通过校园网或学校 VPN 访问。
