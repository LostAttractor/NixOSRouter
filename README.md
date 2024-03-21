# ChaosAttractor's Router Configuration

## TODO
- 现在resolved是路由的默认DNS, 并使用 dnsmasq 作为上游, 但好像并没有转发请求给 dnsmasq, 看起来会并发请求networkd提供的上游和dnsmasq，按需采用
- dae 没有 UDP 连接追踪, 实现起来也较为困难, 此问题已在此被追踪: https://github.com/daeuniverse/dae/issues/475
- sing-box & tproxy?
- nf_conntrack_acct
- 通过networkd设置NAT合理吗，因为networkd不是根据来源进行NAT，而是根据目标NAT
- 代理VLAN隔离（DAE只代理接口而不是整个网桥，尚不清楚DAE能不能判断桥的来源）
- VLAN分配和VLAN二层互通（for wifi & 代理隔离）/三层转发，以及安全（生产）域划分
- 防火墙策略是否合理？是否默认连入应该是阻断？开一个单独的非阻断VLAN？

  要对外提供服务，而且我希望默认就可以连入，设备自己负责防火墙
  
  但默认全通还是太极端了，并不是所有设备都有很强的安全策略，而且弱安全区域的设备被攻击可以扩散到强安全域
  
  或许可以对所有进入安全域的流量做筛查，也就是如果目标是安全域，全部做排查，此外根据来源按需放行（常规域的设备自行负责安全，但防止向安全域扩散）
  记得在chain末尾设置drop
- Jambo Frame

## 地址
### IPv4
#### 地址
WAN 通过 PPP(IPCP)/DHCP 获得地址
#### 路由
进行 NAT

WAN 口获得到的 IP, 上游可以正确路由, 通过 masquerade, 所有连接都从路由本机发出(转发)

### IPv6
#### 地址
WAN 接口通过 DHCP-PD 获取前缀, LAN 接口通过前缀获得地址, 同时通过 SLAAC 获得一个地址, 不使用 DHCP

#### 路由
##### 下行
DHCP-PD 可以使上游将整个段都路由到我的路由器
##### 上行
对于 PPP, 不依赖 default route, 直接 NDP 就能连接, 上游直接是二层网络

对于 DHCP，需要 default route, 因为 WAN 和上游的 PPP 不是二层桥接, 上游还需要进行三层转发

不过, SLAAC 可以自动添加 default route

此外，最好不要关闭AcceptRA, 不接收RA容易导致地址更新不及时（存疑）

## DNS
使用 dnsmasq 作为本地 DNS 服务器, 通过 DHCP 和 SLAAC 提供给 LAN 设备

systemd-resolved 提供上游 DNS信息 给 dnsmasq, 同时也作为路由器的 DNS 服务器，具体来说：

- systemd-resolved 会和 systemd-networkd 联动, 从而获得接口的上游DNS, 不过目前 networkd 还无法获得 PPP 接口的 DNS

- 然后他会和 dnsmasq 联动, 提供上游DNS信息给 dnsmasq, 详见`services.dnsmasq.resolveLocalQueries`:
  - https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/system/boot/resolved.nix
  - https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/networking/dnsmasq.nix

具体信息可以通过 `resolvectl status` 查看

同时, systemd-resolved 的全局上游 DNS 会被设置成 dnsmasq, 亦会同时使用接口的上游 DNS 进行解析

TODO: 理解解析逻辑

### DNS 服务器地址
- 127.0.0.1/192.168.8.1: dnsmasq
- 127.0.0.53: systemd-resolved

### DAE
dae 会劫持所有来自 dnsmasq 和 systemd-resolved 的 DNS 请求 (向上游查询的请求), 其他请求则只分流, 不进入 DNS 模块

会 reject 所有和广告相关的域名的请求, 直连 (asis) 所有中国域名的请求, 并重路由其他请求到 GoogleDNS

并返回 TTL 为0的结果, 这用于保证嗅探可用, dae 自己提供了 DNS 缓存, 所以不会每次都向上游请求

对于重路由, dae 会转发该请求, 并重新进行分流, 分流后会绕过 DNS 模块

TODO: pname逻辑有问题

### DHCP/DNS 权威解析 (TODO)

## 防火墙（TODO）
### pMTU
会把所有经过 forward 链的流量的 MTU 都设置成 pMTU

### Filter（TODO）

## VPN（Wireguard/TODO）

## 硬件转发（TODO）
- Flowtable Offload
- OVS Offload

## 5G CPE 热备（TODO）

## 拓扑 (TODO）

## DAE (TODO)

## Proxmox Image
To generate proxmox image:
```sh
nix run github:nix-community/nixos-generators -- -c proxmox.nix -f proxmox
```
