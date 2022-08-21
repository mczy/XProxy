# XProxy

> 虚拟代理网关，对局域网设备进行透明代理

+ 基于容器运行，无需修改主机路由配置，开箱即用

+ 独立的MAC地址，与宿主机网络栈无耦合，随开随关

+ 允许自定义DNS、上游网关、IP地址等网络选项

+ 支持TCP、UDP流量代理，完整的Fullcone NAT支持

+ 完全兼容IPv6，支持SLAAC地址分配，RRDNS与DNSSL配置

+ （待支持）DHCP与DHCPv6地址自动分配

## 配置格式

XProxy支持YAML与JSON格式的配置文件，包含以下部分：

```yaml
proxy:
  ··· 代理选项 ···

network:
  ··· 网络选项 ···

update:
  ··· 路由资源 ···

custom:
  ··· 自定义脚本 ···

radvd:
  ··· IPv6路由广播 ···

```

### 代理选项

```yaml
# 以下配置仅为示范
proxy:
  log: info
  core: xray
  http:
    web: 8080
  socks:
    proxy: 1094
    direct: 1084
    proxy6: 1096
    direct6: 1086
  addon:
    - tag: metrics
      port: 9090
      protocol: dokodemo-door
      settings:
        address: 127.0.0.1
  sniff:
    enable: true
    redirect: false
    exclude:
      - Mijia Cloud
      - courier.push.apple.com
```

+ `log` ：代理日志级别，可选 `debug` 、`info` 、`warning` 、`error` 、`none` ，默认为 `warning` ；

+ `core` ：代理内核类型，可选 `xray` 、`v2ray` 、`sagray`，默认为 `xray` ；

+ `http` 与 `socks` ：配置 http 与 socks5 入站代理，使用 `key: value` 格式，前者指定入站标志（路由配置中的inboundTag），后者指定监听端口；

+ `addon` ：自定义入站选项，具体格式可见[内核文档](https://xtls.github.io/config/inbound.html#inboundobject)；

+ `sniff` ：嗅探选项，用于获取透明代理中的连接域名

    + `enable` ：是否启用嗅探功能，默认为 `false` ；

    + `redirect` ：是否使用嗅探结果覆盖目标地址，默认为 `false`（v2ray内核不支持）；

    + `exclude` ：不进行覆盖的域名列表（仅xray内核支持）；

### 网络选项

```yaml
# 以下配置仅为示范
network:
  dns:
    - 223.6.6.6
    - 119.29.29.29
  ipv4:
    gateway: 192.168.2.2
    address: 192.168.2.4/24
  ipv6:
    gateway: fc00::2
    address: fc00::4/64
  bypass:
    - 169.254.0.0/16
    - 224.0.0.0/3
    - fc00::/7
    - fe80::/10
    - ff00::/8
```

+ `dns` ：指定系统DNS服务器

+ `ipv4` 与 `ipv6` ：指定IPv4与IPv6的网络信息，其中 `gateway` 为上游网关地址，`address` 为虚拟网关地址（CIDR格式，包含子网长度）；

+ `bypass` ：不进行代理的目标网段，建议绕过以下5个网段：

  + `169.254.0.0/16` ：IPv4链路本地地址

  + `224.0.0.0/3` ：D类多点播送地址，E类保留地址

  + `fc00::/7` ：IPv6唯一本地地址

  + `fe80::/10` ：IPv6链路本地地址

  + `ff00::/8` ：IPv6组播地址

### 路由资源

```yaml
# 以下配置仅为示范
update:
  cron: "0 0 4 * * *"
  url:
    geoip.dat: "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
    geosite.dat: "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"
```

+ `cron` ：触发更新的Cron表达式（此处表示每日凌晨4点更新）；

+ `url` ：更新的文件名及下载地址；

### 自定义脚本

```yaml
# 以下配置仅为示范
custom:
  - "iptables -t nat -A PREROUTING -d 192.168.2.4 -p udp --dport 53 -j DNAT --to-destination 192.168.2.3:5353"
  - "iptables -t nat -A POSTROUTING -d 192.168.2.3 -p udp --dport 5353 -j SNAT --to 192.168.2.4"
  - "iptables -t nat -A PREROUTING -d 192.168.2.4 -p tcp --dport 53 -j DNAT --to-destination 192.168.2.3:5353"
  - "iptables -t nat -A POSTROUTING -d 192.168.2.3 -p tcp --dport 5353 -j SNAT --to 192.168.2.4"
  - "ip6tables -t nat -A PREROUTING -d fc00::4 -p udp --dport 53 -j DNAT --to-destination [fc00::3]:5353"
  - "ip6tables -t nat -A POSTROUTING -d fc00::3 -p udp --dport 5353 -j SNAT --to fc00::4"
  - "ip6tables -t nat -A PREROUTING -d fc00::4 -p tcp --dport 53 -j DNAT --to-destination [fc00::3]:5353"
  - "ip6tables -t nat -A POSTROUTING -d fc00::3 -p tcp --dport 5353 -j SNAT --to fc00::4"
```

自定义脚本命令，在启动代理前将依次执行；

### IPv6路由广播

```yaml
radvd:
  log: 3
  enable: false
  option:
    AdvSendAdvert: on
    AdvManagedFlag: off
    AdvOtherConfigFlag: off
    MinRtrAdvInterval: 10
    MaxRtrAdvInterval: 30
    MinDelayBetweenRAs: 3
  client:
    - fc00::5
  prefix:
    cidr: fc00::4/64
    option:
      AdvOnLink: on
      AdvAutonomous: on
      AdvRouterAddr: off
      AdvValidLifetime: 600
      AdvPreferredLifetime: 100
  route:
    cidr: ""
    option: null
  rdnss:
    ip:
      - fc00::3
      - fc00::4
    option: null
  dnssl:
    suffix:
      - scut.343.re
    option: null
```

默认情况下为 `stateless` 无状态模式，自动根据容器IPv6地址发布RA报文。如果需要配置为 `stateful` 或无状态DHCPv6模式，修改 `AdvManagedFlag` 与 `AdvOtherConfigFlag` 的状态即可（两者分别对应RA报文的M字段与O字段），其他参数的解释可见[man手册](https://linux.die.net/man/5/radvd.conf)，需要注意的是，此处配置文件仅支持上述11个核心参数，其他选项将被忽略。

待补充...

## 部署流程

1. 初始配置

```
# 开启网卡混杂模式
shell> ip link set eth0 promisc on

# 启用IPv6内核模块
shell> modprobe ip6table_filter
```

在 Docker 中创建 macvlan 网络

```
# 网段与网关信息按实际网络指定
shell> docker network create -d macvlan \
  --subnet=192.168.2.0/24 \
  --gateway=192.168.2.1 \
  --subnet=fc00::/64 \
  --gateway=fc00::1 \
  --ipv6 -o parent=eth0 macvlan
```

2. 开始部署

> 本项目基于Docker构建，在 [Docker Hub](https://hub.docker.com/repository/docker/dnomd343/xproxy) 或 [Github Package](https://github.com/dnomd343/XProxy/pkgs/container/xproxy) 可以查看已构建的各版本镜像。

`XProxy` 同时发布在多个镜像源上（国内网络可首选阿里云仓库）：

+ `Docker Hub` ：`dnomd343/xproxy`

+ `Github Package` ：`ghcr.io/dnomd343/xproxy`

+ `阿里云镜像` ：`registry.cn-shenzhen.aliyuncs.com/dnomd343/xproxy`

> 下述命令中，容器路径可替换为上述其他源

使用以下命令启动虚拟网关

```
shell> docker run --restart always \
  --privileged --network macvlan -dt \
  --name scutweb --hostname scutweb \
  --volume /etc/scutweb/:/xproxy/ \
  --volume /etc/timezone:/etc/timezone:ro \ # 以下两句可选，用于映射宿主机时区信息
  --volume /etc/localtime:/etc/localtime:ro \
  dnomd343/xproxy:latest
```

其中 `--privileged` 启动特权模式，否则容器内部无法配置网络信息；配置文件将存储在本机 `/etc/scutweb/` 目录下；容器内部默认为 UTC0 时区，映射宿主机时间配置文件用于两者同步。

成功运行以后，存储目录将生成以下文件夹

+ `assets`：存储路由资源文件

+ `config`：存储代理配置文件

+ `log`：存储日志文件

**路由资源文件夹**

`assets` 目录默认放置 `geoip.dat` 与 `geosite.dat` 路由规则文件，分别存储IP与域名归属信息，在 `update` 中配置的自动更新将保存到此处；本目录亦可放置自定义规则文件，在代理[路由配置](https://xtls.github.io/config/routing.html#ruleobject)中以 `ext:${FILE}:tag` 格式引用。

**代理配置文件夹**

`config` 目录存储代理配置文件，所有 `.json` 后缀文件均会被载入，容器初始化时会使用以下默认配置：

`dns.json` 指定路由匹配时的DNS服务器，默认使用主机DNS，具体原理见[Xray文档](https://xtls.github.io/config/dns.html)

```
{
  "dns": {
    "servers": [
      "localhost"
    ]
  }
}
```

`outbounds.json` 默认配置流量转发给上游网关，需要用户手动配置为上游接口，具体语法见[Xray文档](https://xtls.github.io/config/outbound.html)

```
{
  "outbounds": [
    {
      "tag": "node",
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
```

`routing.json` 默认配置将全部流量交由 `node` 接口，即 `outbounds.json` 中的 `freedom` 出口，具体语法见[Xray文档](https://xtls.github.io/config/routing.html)

```
{
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "network": "tcp,udp",
        "outboundTag": "node"
      }
    ]
  }
}
```

此外，本目录下所有后缀为 `.json` 的文件将被加载到Xray中，使用[多文件配置](https://xtls.github.io/config/features/multiple.html)方式执行，容器内已预置 `log.json` 与 `inbounds.json` 两个文件，分别控制日志模块与入站流量，在 `config` 目录下创建同名文件可实现覆盖效果，不过若配置有误将导致代理失效，正常情况下不建议修改这两个文件。

**日志文件夹**

`log` 目录用于放置日志文件，代理数据将记录到 `access.log` 和 `error.log` 中。


在更改完以上参数后，重启容器即可生效

```
shell> docker restart -t=0 scutweb
```

受限于macvlan机制，宿主机无法直接与macvlan容器通讯，需要配置网桥才能让宿主机访问虚拟网关。

```
shell> vim /etc/network/interfaces
```

补充如下配置

```
# 具体网络信息需要按实际情况指定
auto eth0
iface eth0 inet manual

auto macvlan
iface macvlan inet static
  address 192.168.2.34   # 宿主机静态IP地址
  netmask 255.255.255.0  # 子网掩码
  gateway 192.168.2.2    # 虚拟网关IP地址
  dns-nameservers 192.168.2.3  # DNS主服务器
  dns-nameservers 192.168.2.1  # DNS备用服务器
  pre-up ip link add macvlan link eth0 type macvlan mode bridge
  post-down ip link del macvlan link eth0 type macvlan mode bridge
  # 搭建网桥macvlan，用于与虚拟网关通讯
```

重启宿主机网络生效（或直接重启宿主机）

```
shell> /etc/init.d/networking restart
[ ok ] Restarting networking (via systemctl): networking.service.
```

配置完成后，容器IP为虚拟旁路由网关地址，设备网关设置为该地址即可正常上网。

对于非静态IP地址设备（常见情况）有以下情形：

+ 在IPv4上，修改路由器DHCP设置，将网关指向容器IP即可全局生效

+ 在IPv6上，容器默认会启动IPv6路由组播机制，内网设备将会无状态配置子网地址，网关地址自动指向容器链路本地地址，该配置可全局生效（需关闭路由器IPv6分配，避免冲突）

对于静态IP地址设备（非常见情况）有以下情形：

+ 在IPv4上，修改设备网关为容器IPv4地址

+ 在IPv6上，修改设备地址至容器指定子网内，网关地址配置为容器IPv6地址（非链路本地地址）

综上，开启虚拟网关前需关闭路由器IPv6地址分配，而后连入设备将自动适配IPv4与IPv6网络（绝大多数设备均以DHCP与IPv6路由器发现机制联网），对于此前在内网固定IP地址的设备，手动为其配置网关地址即可。