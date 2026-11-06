// Tencent direct routing; maintained outside subscription content.
function main(config, profileName) {
  const rules = ["PROCESS-NAME,QQ.exe,DIRECT", "PROCESS-NAME,Weixin.exe,DIRECT", "PROCESS-NAME,WeChat.exe,DIRECT", "PROCESS-NAME,WeChatAppEx.exe,DIRECT", "DOMAIN-SUFFIX,code.tencent.com,DIRECT", "DOMAIN-SUFFIX,tencent.com,DIRECT", "DOMAIN-SUFFIX,qq.com,DIRECT", "DOMAIN-SUFFIX,qcloud.com,DIRECT", "DOMAIN-SUFFIX,myqcloud.com,DIRECT", "DOMAIN-SUFFIX,tencentcloud.com,DIRECT", "DOMAIN-SUFFIX,tencent-cloud.com,DIRECT", "DOMAIN-SUFFIX,qcloudimg.com,DIRECT", "DOMAIN-SUFFIX,gtimg.com,DIRECT", "DOMAIN-SUFFIX,idqqimg.com,DIRECT", "DOMAIN-SUFFIX,wechat.com,DIRECT", "DOMAIN-SUFFIX,weixin.com,DIRECT", "DOMAIN-SUFFIX,servicewechat.com,DIRECT", "DOMAIN-SUFFIX,wegame.com,DIRECT", "DOMAIN-SUFFIX,wegame.com.cn,DIRECT", "DOMAIN-SUFFIX,tenpay.com,DIRECT", "GEOSITE,tencent,DIRECT"];
  config.rules = [...rules, ...(config.rules || []).filter(rule => !rules.includes(rule))];
  config.dns = config.dns || {};
  const filters = ["+.code.tencent.com", "+.tencent.com", "+.qq.com", "+.qcloud.com", "+.myqcloud.com", "+.tencentcloud.com", "+.tencent-cloud.com", "+.qcloudimg.com", "+.gtimg.com", "+.idqqimg.com", "+.wechat.com", "+.weixin.com", "+.servicewechat.com", "+.wegame.com", "+.wegame.com.cn", "+.tenpay.com"];
  config.dns["fake-ip-filter"] = [...new Set([...(config.dns["fake-ip-filter"] || []), ...filters])];
  return config;
}
