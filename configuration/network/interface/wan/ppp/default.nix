{ network, ... }:
{
  imports = [ ./pppd.nix ];

  # https://github.com/JQ-Networks/NixOS/blob/a7bf792a4411971d8229eb43a3547097ab06e65b/services/ppp/default.nix#L137
  # https://github.com/RMTT/machines/blob/b58cddca27d81c8bed8fa44e1db4b20dceded40d/nixos/modules/services/pppoe.nix#L49
  systemd.network = {
    networks."10-${network.interface.wan}" = {  # ONU上联接口
      name = network.interface.wan;
      networkConfig.DHCP = "yes";
      dhcpV4Config = {
        UseRoutes = false;
        UseDNS = false;
      };
    };
    networks."10-${network.interface.ppp}" = {
      name = network.interface.ppp;
      networkConfig = {
        IPv6AcceptRA = false;  # DHCP-PD本身就可以拿到地址，我们不需要RA提供的地址...?
        DHCP = "ipv6";  # 需要先接收到 RA 才会尝试 DHCP-PD, 且默认情况下 RA 必须包含 M Flag
        KeepConfiguration = "static";  # 防止清除 PPPD 设置的 IPV4(IPCP) 地址
        # DHCPPrefixDelegation = true;  # 让当前接口也像 br-lan 一样通过 PD 获得一个地址，但是因为 br-lan 已经有一个地址了，意义不大
      };
      dhcpV6Config = {
        UseAddress = false;  # 似乎因为是DHCP-PD, 会一直认为自己拿不到地址
        WithoutRA = "solicit";  # 允许上游 RA 没有 M Flag 时启用 DHCP-PD
        UseDNS = false;
      };
      dhcpPrefixDelegationConfig = {  # 声明自己是上行链路，自己就具有 PD
        UplinkInterface = ":self";
        SubnetId = 0;
        Announce = false;
      };
      routes = [
        { routeConfig = { Gateway = "0.0.0.0"; }; }  # v4默认路由, 因为v4不是networkd管理的，所以仅在reconfigure时工作
        { routeConfig = { Gateway = "::"; }; }  # v6默认路由
      ];
    };
  };

  networking.nftables.ruleset = ''
    define DEV_WORLD = ${network.interface.ppp}
    define DEV_ONU = ${network.interface.wan}

    table inet nat {
      chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;

        # Masquerade private IP addresses
        ip saddr $NET_PRIVATE oifname $DEV_WORLD masquerade

        # Upstream does not know which interface it should send $NET_PRIVATE to, there is not route and gateway
        ip saddr $NET_PRIVATE oifname $DEV_ONU masquerade
      }
    }
  '';
}