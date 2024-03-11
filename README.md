# ChaosAttractor's Router Configuration

## TODO
- 现在resolved是路由的默认DNS, 并使用 dnsmasq 作为上游, 但好像并没有转发请求给 dnsmasq, 而是发给了networkd提供的上游
- dae 没有 UDP 连接追踪, 实现起来也较为困难, 此问题已在此被追踪: https://github.com/daeuniverse/dae/issues/475
- sing-box & tproxy?

## 概述
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

### DNS
使用 dnsmasq 作为本地 DNS 服务器, 通过 DHCP 和 SLAAC 提供给 LAN 设备

systemd-resolved 提供上游 DNS信息 给 dnsmasq, 同时也作为路由器的 DNS 服务器，具体来说：

- systemd-resolved 会和 systemd-networkd 联动, 从而获得接口的上游DNS, 不过目前 networkd 还无法获得 PPP 接口的 DNS

- 然后他会和 dnsmasq 联动, 提供上游DNS信息给 dnsmasq, 详见`services.dnsmasq.resolveLocalQueries`:
  - https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/system/boot/resolved.nix
  - https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/networking/dnsmasq.nix

具体信息可以通过 `resolvectl status` 查看

同时, systemd-resolved 的全局上游 DNS 会被设置成 dnsmasq, 亦会同时使用接口的上游 DNS 进行解析

TODO: 理解解析逻辑

#### DNS 服务器地址

- 127.0.0.1/192.168.8.1: dnsmasq
- 127.0.0.53: systemd-resolved

#### DAE
dae 会劫持所有来自 dnsmasq 和 systemd-resolved 的 DNS 请求 (向上游查询的请求), 其他请求则只分流, 不进入 DNS 模块

会 reject 所有和广告相关的域名的请求, 直连 (asis) 所有中国域名的请求, 并重路由其他请求到 GoogleDNS

并返回 TTL 为0的结果, 这用于保证嗅探可用, dae 自己提供了 DNS 缓存, 所以不会每次都向上游请求

对于重路由, dae 会转发该请求, 并重新进行分流, 分流后会绕过 DNS 模块

TODO: pname逻辑有问题

### 防火墙
#### MTU
会把所有经过 forward 链的流量的 MTU 都设置成 pMTU

#### TODO: Filter

## Proxmox Image
To generate proxmox image:
```sh
nix run github:nix-community/nixos-generators -- -c proxmox.nix -f proxmox
```
