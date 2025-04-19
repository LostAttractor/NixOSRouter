{ network, pkgs, ... }:
{
  imports = [
    ./pppd.nix
    (import ../qos.nix ({ inherit pkgs; interface = network.interface.ppp; }))
  ];

  # https://github.com/JQ-Networks/NixOS/blob/a7bf792a4411971d8229eb43a3547097ab06e65b/services/ppp/default.nix#L137
  # https://github.com/RMTT/machines/blob/b58cddca27d81c8bed8fa44e1db4b20dceded40d/nixos/modules/services/pppoe.nix#L49
  systemd.network = {
    networks."10-${network.interface.onu}" = {  # ONU上联接口 / 仅用于管理ONU
      name = network.interface.onu;
      routes = [{ Destination = "192.168.11.0/24"; }];
    };
    networks."10-${network.interface.ppp}" = {
      name = network.interface.ppp;
      networkConfig = {
        DHCP = "ipv6";  # 需要先接收到包含 M Flag 的 RA 才会尝试 DHCP-PD
        KeepConfiguration = "static";  # 防止清除 PPPD 通过 IPCP 获取的 IPV4 地址
        DefaultRouteOnDevice = true; # 设置默认路由到该接口
      };
      dhcpV6Config = {
        UseAddress = false;  # 使用 SLAAC
        UseDNS = false; # TODO: Why?
      };
      ipv6AcceptRAConfig.DHCPv6Client = "always";
    };
  };

  network.interface.world = network.interface.ppp;
  network.interface.worlds = [ network.interface.ppp ];
}