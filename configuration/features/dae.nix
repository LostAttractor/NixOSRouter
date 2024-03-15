{ config, ... }:
{
  services.dae = {
    enable = true;
    configFile = config.sops.templates."config.dae".path;
  };

  sops.templates."config.dae".content = ''
    global {
      # Bind to LAN and/or WAN as you want. Replace the interface name to your own.
      lan_interface: br-lan, wg0
      wan_interface: auto # Use "auto" to auto detect WAN interface.

      log_level: info
      allow_insecure: false
      auto_config_kernel_parameter: true

      # domain:   将通过SNI嗅探获得目标, 并发起一次DNS请求验证SNI的域名的解析结果是否和请求的目标一致
      #           如果一致, 则覆盖发送到代理节点的包中的目标
      #           这种验证需求请求发起时的使用的DNS结果和dae的DNS缓存的结果一致,这至少要求向上游DNS的查询被劫持, 或许还需要保证没有额外的DNS缓存
      #           同时还会验证DNS查询是否经过dae
      # domain+:  忽略DNS验证, 一般来说这允许你的DNS查询不经过dae或是有缓存时也能工作
      #           不过这可能导致提供了错误的SNI的情况下无法工作, 如APNS
      # domain++: 忽略验证的同时, 以嗅探到的目标重新进行路由, 这意味着连接的目标将会是域名而非IP
      #           同时也意味着整个过程中，如果域名分流正确工作，可以抵御域名污染
      #           但这也带来了更大的性能开销
      # dial_mode: domain++  # SNI错误是个问题, 默认的domain模式需要dnsmasq遵守上游ttl(0)
    }

    subscription {
      # Fill in your subscription links here.
      nexitally: '${config.sops.placeholder."dae/subscription/nexitally"}'
    }

    # See https://github.com/daeuniverse/dae/blob/main/docs/en/configuration/dns.md for full examples.
    dns {
      upstream {
        googledns: 'tcp+udp://dns.google.com:53'
      }
      routing {
        request {
          qname(geosite:category-ads-all) -> reject
          qname(geosite:cn) -> asis
          fallback: googledns
        }
      }
    }

    group {
      proxy {
        filter: name(keyword: 'Japan') && !name(keyword: 'Premium')
        policy: min_avg10
      }
    }

    # See https://github.com/daeuniverse/dae/blob/main/docs/en/configuration/routing.md for full examples.
    routing {
      # Because there is currently no UDP conntrack,
      # you need to allow the UDP Server's reply traffic to be directly connected
      # https://github.com/daeuniverse/dae/issues/475
      # For example: dnsmasq
      pname(dnsmasq) -> direct
      
      # Hijack only DNS queries from dnsmasq and systemd-resolved
      dport(53) && pname(dnsmasq) -> direct
      dport(53) && pname(systemd-resolved) -> direct
      dport(53) -> must_rules
      # TODO: Should be equivalent but doesn't work now
      # https://github.com/daeuniverse/dae/issues/474
      # dport(53) && !pname(systemd-resolved) && !pname(dnsmasq) -> must_rules

      ### Write your rules below.

      dip(geoip:private) -> direct
      dip(geoip:cn) -> direct
      domain(geosite:cn) -> direct

      fallback: proxy
    }
  '';

  sops.secrets."dae/subscription/nexitally" = {};
}