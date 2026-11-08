function main(config) {
  const domain = 'board.example.ts.net';
  const node = 'ts-flclash-board';
  const hostname = 'flclash-board';

  if (!config || typeof config !== 'object' || !Array.isArray(config.rules)) {
    throw new Error('订阅配置缺少规则列表');
  }
  if (config.proxies !== undefined && !Array.isArray(config.proxies)) {
    throw new Error('订阅配置的代理列表格式无效');
  }
  if (config['proxy-groups'] !== undefined && !Array.isArray(config['proxy-groups'])) {
    throw new Error('订阅配置的策略组格式无效');
  }
  if ((config['proxy-groups'] || []).some((group) => group && group.name === node)) {
    throw new Error('Tailscale 节点名称已被策略组占用');
  }
  const proxies = config.proxies || [];
  const existing = proxies.find((proxy) => proxy && proxy.name === node);
  if (existing && (existing.type !== 'tailscale' || existing.hostname !== hostname)) {
    throw new Error('Tailscale 节点名称已被其他代理占用');
  }
  if (!existing) {
    config.proxies = [...proxies, {name: node, type: 'tailscale', hostname}];
  }

  const dns = config.dns || {};
  const filterMode = dns['fake-ip-filter-mode'] || 'blacklist';
  const filter = dns['fake-ip-filter'] || [];
  if (!Array.isArray(filter)) throw new Error('DNS 过滤列表格式无效');
  let filterRule;
  if (filterMode === 'blacklist') filterRule = domain;
  else if (filterMode === 'rule') filterRule = `DOMAIN,${domain},real-ip`;
  else throw new Error('请先核查 DNS fake-ip 白名单');

  dns.enable = true;
  dns['nameserver-policy'] = {...(dns['nameserver-policy'] || {}), [domain]: `ts://${node}`};
  dns['fake-ip-filter'] = [filterRule, ...filter.filter((item) => item !== filterRule)];
  config.dns = dns;
  const rule = `DOMAIN,${domain},${node}`;
  config.rules = [rule, ...config.rules.filter((item) => item !== rule)];
  return config;
}
