{ network, pkgs, ... }:
{
  import = [ (import ../qos.nix ({ inherit pkgs; interface = network.interface.onu; })) ];

  # https://www.freedesktop.org/software/systemd/man/latest/systemd.network.html
  # Example 3. IPv6 Prefix Delegation (DHCPv6 PD)
  systemd.network = {
    networks."10-${network.interface.onu}" = {
      name = network.interface.onu;
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;  # 由于 systemd 需要知道 RA 的详细信息, 因此 kernel 的 accept_ra 需要禁用
      };
      # Add in systemd-networkd version 255
      dhcpV4Config.RequestAddress = "192.168.1.2";
      # 允许上游提供 RA 但却没有 M Flag 时启用 DHCP-PD (不使用DHCP获得地址)
      dhcpV6Config.UseAddress = false;
      ipv6AcceptRAConfig.DHCPv6Client = "always";
    };
  };

  network.interface.world = network.interface.onu;
  network.interface.worlds = [ network.interface.onu ];
}