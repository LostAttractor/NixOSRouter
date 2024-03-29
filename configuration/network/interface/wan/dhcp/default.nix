{ network, ... }:
{
  systemd.network = {
    networks."10-${network.interface.wan}" = {
      name = network.interface.wan;
      networkConfig = {
        DHCP = "yes";
        Address = "192.168.1.2/24";
        # DHCPPrefixDelegation = true;  # 让当前接口也像 br-lan 一样通过 PD 获得一个地址
      };
      dhcpV4Config.UseRoutes = false;
      dhcpV6Config = {
        WithoutRA = "solicit";  # 允许上游 RA 没有 M Flag 时启用 DHCP-PD
        UseAddress = false;  # 不通过 DHCP 获取地址，或上游只提供前缀，且无法通过其他方法获得地址时也需要
      };
      dhcpPrefixDelegationConfig = {  # 声明自己是上行链路，自己就具有 PD
        UplinkInterface = ":self";
        SubnetId = 0;
        Announce = false;
      };
      # 将 v4 默认路由的 src 改为设置的静态地址
      routes = [{ routeConfig = { Gateway = "_dhcp4"; PreferredSource = "192.168.1.2"; }; }];
    };
  };

  network.nftables.interface.world = network.interface.wan;
  
  # AUTHORITATIVE SERVER
  services.dnsmasq.settings.auth-server = "router.lostattractor.net,${network.interface.wan}";
}