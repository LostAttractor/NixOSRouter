{ network, ... }:
{
  systemd.network = {
    networks."10-${network.interface.security}" = {
      name = network.interface.security;
      networkConfig = {
        Address = [ "10.10.0.1/16" "fd23:3333:3333:10::1/64" ];
        IPv6SendRA = true; # 会自动关闭 IPv6AcceptRA 并打开 IPv6Forwarding
      };
      ipv6SendRAConfig = { Managed = true; OtherInformation = true; };
    };
  };

  network.interface.private.security = network.interface.security;
}