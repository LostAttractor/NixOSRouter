{ network, ... }:
{
  systemd.network = {
    networks."10-${network.interface.tor}" = {
      name = network.interface.tor;
      networkConfig = {
        Address = [ "10.1.0.1/16" "fd23:3333:3333:1::1/64" ];
        DHCPPrefixDelegation = true;  # 自动选择第一个有 PD 的链路, 并获得子网前缀
        IPv6SendRA = true; # 会自动关闭 IPv6AcceptRA 并打开 IPv6Forwarding
        LLDP = true;
        EmitLLDP = true;
      };
      ipv6SendRAConfig = { Managed = true; OtherInformation = true; };
      dhcpPrefixDelegationConfig = {
        SubnetId = 1;
        Token = "::1";
      };
    };
  };

  network.interface.private.tor = network.interface.tor;
}