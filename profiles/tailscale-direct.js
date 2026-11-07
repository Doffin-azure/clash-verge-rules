// Tailscale DNS and domain routing; keep independent of subscription content.
function applyTailscaleDirect(config) {
  if (!config || typeof config !== "object" || Array.isArray(config)) {
    throw new Error("Expected a Clash configuration object");
  }
  const existingRules = config.rules == null ? [] : config.rules;
  const existingDns = config.dns == null ? {} : config.dns;
  if (!Array.isArray(existingRules) || typeof existingDns !== "object" || Array.isArray(existingDns)) {
    throw new Error("Expected rules to be an array and dns to be an object");
  }
  const existingFilter = existingDns["fake-ip-filter"] == null ? [] : existingDns["fake-ip-filter"];
  const existingPolicy = existingDns["nameserver-policy"] == null ? {} : existingDns["nameserver-policy"];
  if (!Array.isArray(existingFilter) || typeof existingPolicy !== "object" || Array.isArray(existingPolicy)) {
    throw new Error("Expected fake-ip-filter to be an array and nameserver-policy to be an object");
  }
  const mode = existingDns["fake-ip-filter-mode"] == null ? "blacklist" : existingDns["fake-ip-filter-mode"];
  if (!["blacklist", "whitelist", "rule"].includes(mode)) {
    throw new Error("Unsupported fake-ip-filter-mode");
  }

  const rules = ["DOMAIN-SUFFIX,ts.net,DIRECT", "IP-CIDR,100.100.100.100/32,DIRECT,no-resolve"];
  const policy = { ...existingPolicy };
  const existingTsPolicy = Object.keys(policy).some(key => ["ts.net", "+.ts.net", "*.ts.net"].includes(key.toLowerCase()));
  if (!existingTsPolicy) policy["+.ts.net"] = "100.100.100.100";

  const dns = { ...existingDns, "nameserver-policy": policy };
  if (mode === "blacklist") {
    dns["fake-ip-filter"] = ["+.ts.net", ...existingFilter.filter(entry => entry !== "+.ts.net")];
  } else if (mode === "rule") {
    const realIpRule = "DOMAIN-SUFFIX,ts.net,real-ip";
    dns["fake-ip-filter"] = [realIpRule, ...existingFilter.filter(entry => entry !== realIpRule)];
  }
  // In whitelist mode, matching entries receive fake IPs. Preserve the list.
  config.rules = [...rules, ...existingRules.filter(rule => !rules.includes(rule))];
  config.dns = dns;
  return config;
}

function main(config, profileName) {
  return applyTailscaleDirect(config);
}
