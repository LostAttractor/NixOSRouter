{ network, ... }:
{
  systemd.network = {
    networks."10-${network.interface.security}" = {
      name = network.interface.security;
      networkConfig = {
        Address = [ "10.10.0.1/16" "fd23:3333:3333:10::1/64" ];
        DHCPPrefixDelegation = true;  # 自动选择第一个有 PD 的链路, 并获得子网前缀
        IPv6SendRA = true; # 会自动关闭 IPv6AcceptRA 并打开 IPv6Forwarding
      };
      ipv6SendRAConfig = { Managed = true; OtherInformation = true; };
      dhcpPrefixDelegationConfig = {
        SubnetId = 2;
        Token = "::1";
      };
    };
  };

  network.interface.private.security = network.interface.security;
}