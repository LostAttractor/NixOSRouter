{ network, pkgs, ... }:
{
  imports = [ (import ./qos.nix ({ inherit pkgs; interface = network.interface.cu; })) ];

  systemd.network = {
    networks."10-${network.interface.cu}" = {
      name = network.interface.cu;
      networkConfig = {
        DHCP = "yes";
        VRF = "vrf-cu";
      };
      # dhcpV4Config.UseRoutes = false;
    };
    networks."01-vrf-cu" = {
      name = "vrf-cu";
      routingPolicyRules = [
        {
          Priority = 98;
          To = "54.64.0.0/15";
          Table = 10;
        }
        {
          Priority = 99;
          FirewallMark = 10;
          Table = 52;
        }
        {
          Priority = 100;
          FirewallMark = 10;
          Table = 254;
        }
      ];
    };
    netdevs."00-vrf-cu" = {
      netdevConfig = {
        Kind = "vrf";
        Name = "vrf-cu";
      };
      vrfConfig.Table = 10;
    };
  };

  # fib saddr type != local ct mark set 10?
  # fib only checks main table
  networking.nftables.tables.mangle_vrf = {
    family = "inet";
    content = ''
      chain forward {
          type filter hook forward priority 0; policy accept;
          ct state new ct mark set 10
      }

      chain prerouting {
          type filter hook prerouting priority 0; policy accept;
          ct mark 10 meta mark set 10
      }
    '';
  };

  network.interface.worlds = [ network.interface.cu ];
}