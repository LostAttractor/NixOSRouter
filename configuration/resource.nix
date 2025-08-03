 { pkgs, lib, ... }:
let
  # cdn.jsdelivr.net 在境内仍然不太可用
  bootstrapDNS = "8.8.8.8";
  setup-resource = pkgs.writeShellScript "setup-resource" ''
    set -e

    mkdir -p /tmp/oisd /tmp/v2ray
    if [ ! -e "/tmp/oisd/domainswild2_big.txt" ]; then
      ${pkgs.curl}/bin/curl --resolve big.oisd.nl:443:$(${pkgs.dig}/bin/dig +short @${bootstrapDNS} big.oisd.nl | grep -m 1 '^[.0-9]*$') https://big.oisd.nl/domainswild2 -o /tmp/oisd/domainswild2_big.txt
    fi
    if [ ! -e "/tmp/oisd/dnsmasq2_big.txt" ]; then
      ${pkgs.curl}/bin/curl --resolve big.oisd.nl:443:$(${pkgs.dig}/bin/dig +short @${bootstrapDNS} big.oisd.nl | grep -m 1 '^[.0-9]*$') https://big.oisd.nl/dnsmasq2 -o /tmp/oisd/dnsmasq2_big.txt
    fi
    if [ ! -e "/tmp/v2ray/geoip.dat" ]; then
      ${pkgs.curl}/bin/curl --resolve fastly.jsdelivr.net:443:$(${pkgs.dig}/bin/dig +short @${bootstrapDNS} fastly.jsdelivr.net | grep -m 1 '^[.0-9]*$') https://fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat -o /tmp/v2ray/geoip.dat
    fi
    if [ ! -e "/tmp/v2ray/geosite.dat" ]; then
      ${pkgs.curl}/bin/curl --resolve fastly.jsdelivr.net:443:$(${pkgs.dig}/bin/dig +short @${bootstrapDNS} fastly.jsdelivr.net | grep -m 1 '^[.0-9]*$') https://fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat -o /tmp/v2ray/geosite.dat
    fi
    if [ ! -e "/tmp/v2ray/geosite_cn.txt" ]; then
      ${pkgs.v2dat}/bin/v2dat unpack geosite -o /tmp/v2ray /tmp/v2ray/geosite.dat
    fi
  '';
  update-resource = pkgs.writeShellScript "update-resource" ''
    set -e

    mkdir -p /tmp/oisd /tmp/v2ray
    ${pkgs.curl}/bin/curl --resolve big.oisd.nl:443:$(${pkgs.dig}/bin/dig +short @${bootstrapDNS} big.oisd.nl | grep -m 1 '^[.0-9]*$') https://big.oisd.nl/domainswild2 -o /tmp/oisd/domainswild2_big.txt
    ${pkgs.curl}/bin/curl --resolve big.oisd.nl:443:$(${pkgs.dig}/bin/dig +short @${bootstrapDNS} big.oisd.nl | grep -m 1 '^[.0-9]*$') https://big.oisd.nl/dnsmasq2 -o /tmp/oisd/dnsmasq2_big.txt
    ${pkgs.curl}/bin/curl --resolve fastly.jsdelivr.net:443:$(${pkgs.dig}/bin/dig +short @${bootstrapDNS} fastly.jsdelivr.net | grep -m 1 '^[.0-9]*$') https://fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat -o /tmp/v2ray/geoip.dat
    ${pkgs.curl}/bin/curl --resolve fastly.jsdelivr.net:443:$(${pkgs.dig}/bin/dig +short @${bootstrapDNS} fastly.jsdelivr.net | grep -m 1 '^[.0-9]*$') https://fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat -o /tmp/v2ray/geosite.dat
    ${pkgs.v2dat}/bin/v2dat unpack geosite -o /tmp/v2ray /tmp/v2ray/geosite.dat

    ${pkgs.dae}/bin/dae reload
    ${pkgs.systemd}/bin/systemctl restart mosdns
    ${pkgs.systemd}/bin/systemctl restart dnsmasq
  '';
in
{
  systemd.services.setup-resource = {
    description = "Pre-start script for updating resource for mosdns and dae";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = [ "${pkgs.bash}/bin/bash ${setup-resource}" ];
    };
  };

  # 将 pre-start-script 设置为 mosdns 和 dae 的依赖
  systemd.services.mosdns = {
    after = [ "setup-resource.service" ];
    requires = [ "setup-resource.service" ];
  };

  systemd.services.dae = {
    after = [ "setup-resource.service" ];
    requires = [ "setup-resource.service" ];
  };

  systemd.services.dnsmasq = {
    after = [ "setup-resource.service" ];
    requires = [ "setup-resource.service" ];
    serviceConfig.PrivateTmp = lib.mkForce false;
  };
  
  services.cron = {
    enable = true;
    systemCronJobs = [
      "0 0 * * * root bash ${update-resource}"
    ];
  };
}
