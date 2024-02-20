_:
# https://openwrt.org/docs/guide-user/base-system/dhcp
# https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html
let 
  domain = "home.lostattractor.net";
in {
  services.resolved.enable = false;

  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    settings = {
      # Upstream
      resolv-file = "/etc/ppp/resolv.conf";
      # Local domain
      domain = domain;
      local = "/${domain}/";
      expand-hosts = true;
      # Interface
      interface = "br-lan";
      bind-dynamic = true;
      interface-name = "router.${domain},br-lan";
      # Cache
      cache-size = 8192;
      no-negcache = true;
      # Ensure requests for local host names are not forwarded to upstream DNS servers
      domain-needed = true;
      bogus-priv = true;
      localise-queries = true;  # 关闭此选项似乎会导致包含在 auth-zone 的 CNAME 在非 auth-server 绑定的接口也不返回实际 IP, 尚不清楚成因
      # ARP Bind
      read-ethers = true;
      dhcp-broadcast = "tag:needs-broadcast";
      dhcp-ignore-names = "tag:dhcp_bogus_hostname";
      # DHCP
      dhcp-range = [
        "set:br-lan,192.168.8.100,192.168.8.254"
        "set:br-lan,::ff,::ffff,constructor:br-lan,ra-names,1h"
      ];
      dhcp-authoritative = true;
      # CNAME
      cname = [
        "binarycache.${domain},hydra.${domain}"
        "qbittorrent.${domain},nextcloud.${domain},emby.${domain},nixnas.${domain}"
        "portainer.${domain},uptime.${domain},nginx.${domain},grafana.${domain},prometheus.${domain},alist.${domain},memos.${domain},container.${domain}"
      ];
      # AUTHORITATIVE ZONE
      auth-zone = "${domain}";
    };
  };
}