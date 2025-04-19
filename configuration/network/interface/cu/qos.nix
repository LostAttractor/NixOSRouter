{ pkgs, interface, ... }:
{
  # 流量必须不拥塞在ISP处, 不然一切都没有意义
  # 如果ISP处不存在瓶颈, 则我可以优先丢弃会导致队列膨胀的包, 并接收不导致队列膨胀的包, 而 ISP 限速时使用的丢弃方法一般是rate limit
  # 实际上我的接收没有瓶颈, 但丢弃保证了上游ISP的限速不会触发, 因此不导致队列膨胀的包我可以正常收到, 导致队列膨胀的包则因为丢弃降速以保证上游 ISP 的限速不触发
  # 因此这里使用 CAKE 并锁定速率
  # 但事实上瓶颈可能在光猫的千兆链路? 那其实道理也一样, 不过应该设法解决这个瓶颈
  systemd.network = {
    networks."10-${interface}" = {
      cakeConfig = {
        Bandwidth = "40M";
        RTTSec = "50ms";
      };
    };
    netdevs."00-ifb4${interface}".netdevConfig = {
      Kind = "ifb";
      Name = "ifb4${interface}";
    };
    networks."10-ifb4${interface}" = {
      name = "ifb4${interface}";
      networkConfig.LinkLocalAddressing = "no";
      linkConfig.RequiredForOnline = false;
      cakeConfig = {
        Bandwidth = "1000M";
        OverheadBytes = 50;
        RTTSec = "50ms";
      };
    };
  };

  services.networkd-dispatcher.rules."10-tc-cu" = {
    onState = [ "routable" ]; # or configured
    script = ''
      #!${pkgs.runtimeShell}
      if [[ $IFACE == "${interface}" ]] && ! ${pkgs.iproute2}/bin/tc filter show dev "${interface}" ingress | grep -q "mirred"; then
        # Add parent qdisc if not loaded yet
        if ! tc qdisc show dev ${interface} | grep -q "clsact"; then
          ${pkgs.iproute2}/bin/tc qdisc add dev "${interface}" clsact
        fi
        ${pkgs.iproute2}/bin/tc filter add dev ${interface} ingress matchall action mirred egress redirect dev ifb4${interface}
      fi
    '';
  };
}