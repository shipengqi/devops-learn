---
title: iptables
weight: 1
---

iptables 的核心工作原理可以概括为：“**根据规则，对数据包进行过滤或处理**”。这些规则被组织在预定义的链（Chains） 和表（Tables） 中。

**Tables 由 Chains 组成，而 Chains 又由规则（Rules）组成**。

## 核心思想

### 链

链是规则的集合，这些规则**按顺序排列**。数据包到达某个链时，会**从第一条规则开始依次匹配，一旦匹配成功，就执行该规则定义的动作（如放行、拒绝），并停止后续匹配**。如果所有规则**都不匹配，则执行该链的默认策略**（Policy）。

系统预定义了五个最重要的链（对应数据包流经的不同阶段）：：

- **INPUT**：处理本机接收的数据包（例如，有人 ping 你的机器或 SSH 连接到你的机器）。
- **OUTPUT**：处理本机发出的数据包（例如，你从本机 ping 别人）。
- **FORWARD**：处理经过本机路由的数据包（你的机器充当路由器或网关时）。
- **PREROUTING**：(nat 表) 数据包刚到达防火墙，**在进行路由判断之前**（可用于修改目标地址，即 DNAT）。
- **POSTROUTING**：(nat表) 数据包即将离开防火墙，**在进行路由判断之后**（可用于修改源地址，即 SNAT）。

### 表

系统预定义了五个表，但最常用的是前两个：

- `filter` 表：**负责过滤数据包，决定是否放行**。这是**最常用**的表。
  - 内置链：**INPUT**, **FORWARD**, **OUTPUT**。
- `nat` 表：**负责网络地址转换（NAT）**。
  - 内置链：**PREROUTING (DNAT)**, **OUTPUT**, **POSTROUTING (SNAT)**。
- `mangle` 表：**负责修改数据包的头信息（如 TTL、TOS）**。
  - 内置链：所有五个链 (**PREROUTING**, **INPUT**, **FORWARD**, **OUTPUT**, **POSTROUTING**)。
- `raw` 表：负责连接跟踪机制的处理（如决定是否对数据包进行状态跟踪）。
  - 内置链：**PREROUTING**, **OUTPUT**。
- `security` 表（较少用）：用于强制访问控制（MAC）网络规则。

### 小结

表和链的关系：你可以想象**数据包流经一条“链”时，会依次经过挂在这条链上的不同“表”的规则检查**。

**表的优先级顺序决定了检查的先后次序**：`raw -> mangle -> nat -> filter`。

## 工作流程：数据包的一生

<img src="https://raw.githubusercontent.com/shipengqi/illustrations/refs/heads/main/devops/iptable-data-flow.png" alt="iptables-data-flow" width="70%">

1. **入口 (PREROUTING)**：
   - 数据包从网卡进入系统。
   - 首先经过 **PREROUTING** 链。这里会依次应用 **raw、mangle、nat** 表中的规则。
   - 关键：在 **nat** 表的 **PREROUTING** 链中，可以做 **DNAT（目标地址转换）**，**比如把访问公网IP 80 端口的数据包转发到内网服务器的 `192.168.1.10:80`**。
2. **路由判断 (Routing Decision)**：
   - 内核查看数据包的目标 IP 地址，决定这个包是发给**本机的（走 INPUT 链）**还是需要**转发的（走 FORWARD 链）**。
3. **发给本机 (INPUT)**：
   - 数据包进入 INPUT 链。这里会依次应用 mangle 和 filter 表中的规则。
   - 关键：在 **filter 表的 INPUT 链**中，设置**防火墙规则的主要地方**。比如只允许特定 IP 访问本机的 SSH 端口。 
4. **本机进程处理**：
   - 数据包被本机的用户进程（如 web 服务器、SSH 服务）接收和处理。   
5. **本机发出 (OUTPUT)**：
   - 本机进程产生新的数据包，准备发送出去。
   - 数据包进入 OUTPUT 链。这里会依次应用 raw、mangle、nat、filter 表中的规则。
   - 关键：在 **filter 表的 OUTPUT 链**中，**可以控制本机能发出哪些数据包**。   
6. **转发 (FORWARD)**：
   - 如果数据包是转发的（第2步判断），则进入 FORWARD 链。
   - 这里会依次应用 mangle 和 filter 表中的规则。
   - 关键：在 **filter 表的 FORWARD 链**中，**设置转发规则的主要地方**。比如允许内网网段访问互联网，但禁止两个内网网段之间互访。
7. **出口 (POSTROUTING)**：
   - 所有即将从网卡发出的数据包（**无论是本机产生的还是转发的**），**最后都要经过 POSTROUTING 链**。
   - 这里会依次应用 mangle 和 nat 表中的规则。
   - 关键：在 **nat 表的 POSTROUTING 链**中，**可以做 SNAT（源地址转换），也就是常说的“IP伪装”（Masquerading），让内网机器共享一个公网IP上网**。
8. **离开**：数据包离开网卡，前往下一个目的地。

## 规则匹配与动作（Target）

每条规则都由两部分组成：**匹配条件**（Matches） 和 **动作**（Target）。

- **匹配条件**：例如 `-p tcp --dport 22`（协议是 TCP 且目标端口是 22）、`-s 192.168.1.100`（源 IP 是 `192.168.1.100`）。
- **动作**（Target）：当数据包匹配规则后要执行的操作。常见的有：
  - **ACCEPT**：接受数据包，允许其通过。
  - **DROP**：丢弃数据包，没有任何响应。就像对方从来没发过这个包一样。更安全。
  - **REJECT**：拒绝数据包，并向发送方返回一个 connection refused 的错误消息。更友好。
  - **SNAT**：在 nat 表中使用，修改源地址。
  - **DNAT**：在 nat 表中使用，修改目标地址。
  - **MASQUERADE**：是 SNAT 的一种特殊形式，适用于动态获取 IP 的场合（如拨号上网）。
  - **LOG**：将匹配的数据包信息记录到系统日志（`/var/log/messages` 等），然后继续匹配后续规则。用于调试。

## 命令

命令格式：`iptables [-t 表] 命令选项 [规则链] 规则`
  - `-t` 选项默认使用的是 filter 表。

### 命令选项

- `-A` (Append)	在链的末尾追加一条新规则。
  - 例如：`iptables -A INPUT -s 192.168.1.100 -j DROP` 表示在 INPUT 链的末尾追加一条规则，当源 IP 是 `192.168.1.100` 时，拒绝该数据包。
- `-I` (Insert)	在链的指定位置插入一条新规则（默认为第1条）。
  - 例如：`iptables -I INPUT 3 -p tcp --dport 80 -j ACCEPT` 表示在 INPUT 链的第 3 条位置插入一条规则，当协议是 TCP 且目标端口是 80 时，接受该数据包。
- `-D` (Delete)	从链中删除一条规则。
  - 例如：`iptables -D INPUT -s 192.168.1.100 -j DROP` 表示从 INPUT 链中删除一条规则，当源 IP 是 `192.168.1.100` 时，拒绝该数据包。
- `-F` (Flush) 清空指定链（或所有链）的所有规则。
  - 例如：`iptables -F INPUT` 表示清空 INPUT 链的所有规则。
- `-L` (List) 列出指定链（或所有链）的所有规则。
  - 例如：`iptables -L -n -v` 表示列出所有链的所有规则，且不显示 IP 地址和端口号，而是显示数字形式的 IP 地址和端口号。
- `-N` (New) 创建一条新的用户自定义链。
  - 例如：`iptables -N CUSTOM_CHAIN` 表示创建一条名为 CUSTOM_CHAIN 的用户自定义链。
- `-X` (Delete chain) 删除一条用户自定义链。
  - 例如：`iptables -X CUSTOM_CHAIN` 表示删除名为 CUSTOM_CHAIN 的用户自定义链。
- `-P` (Policy)	设置链的默认策略（所有规则都不匹配时执行的动作）。
  - 例如：`iptables -P INPUT DROP` 表示设置 INPUT 链的默认策略为 DROP，即所有不匹配的数据包都被拒绝。

### 规则选项

- `-i` 输入网口
- `-o` 输出网口
- `-p` 匹配网络协议：tcp、udp、icmp
- `--icmp-type type` 匹配 ICMP 类型，和 `-p icmp` 配合使用。
- `-s` 匹配来源主机（或网络）的IP地址
- `--sport port` 匹配来源主机的端口，和 `-s source-ip` 配合使用。
- `-d` 匹配目标主机的 IP 地址
- `--dport port` 匹配目标主机（或网络）的端口，和 `-d dest-ip` 配合使用。
- `-j` 动作：指定规则匹配后要执行的动作。
  - 例如：`-j ACCEPT` 表示接受该数据包。
  - 例如：`-j DROP` 表示拒绝该数据包。
  - 例如：`-j LOG` 表示记录该数据包的信息到系统日志。
  - 例如：`-j SNAT --to-source 192.168.1.100` 表示修改源地址为 `192.168.1.100`。
  - 例如：`-j DNAT --to-destination 192.168.1.100` 表示修改目标地址为 `192.168.1.100`。
  - 例如：**`-j CUSTOM_CHAIN` 表示跳转到名为 CUSTOM_CHAIN 的用户自定义链**。
  - 例如：`-j MASQUERADE` 表示使用动态获取的 IP 地址进行 SNAT。

### probability

iptables 的 statistic 模块支持**基于概率的规则匹配**，通过 `--mode random` 和 `--probability` 参数实现随机匹配。此功能常用于负载均衡或流量分配。

```bash
iptables -A PREROUTING -t nat -p tcp -d 192.168.1.1 --dport 27017 \
   -m statistic --mode random --probability 0.33 \
   -j DNAT --to-destination 10.0.0.2:1234
iptables -A PREROUTING -t nat -p tcp -d 192.168.1.1 --dport 27017 \
   -m statistic --mode random --probability 0.5 \
   -j DNAT --to-destination 10.0.0.3:1234
iptables -A PREROUTING -t nat -p tcp -d 192.168.1.1 --dport 27017 \
   -j DNAT --to-destination 10.0.0.4:1234
```

- 第一条规则有 `33%` 的概率命中。
- 第二条规则有 `50% × (1 − 33%) = 33%` 的概率命中。
- 第三条规则没有指定 `--probability`，因此剩余的 `34%` 流量会命中。

### 使用场景

```bash
# 1. 设置默认策略（最严格的策略）
iptables -P INPUT DROP    # 默认拒绝所有入站
iptables -P FORWARD DROP  # 默认拒绝所有转发
iptables -P OUTPUT ACCEPT # 默认允许所有出站（通常这样设置）

# 2. 允许本地回环接口（localhost通信）
iptables -A INPUT -i lo -j ACCEPT

# 3. 允许已建立的和相关连接通过（关键！否则无法收到响应包）
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 4. 允许ICMP（ping命令）
iptables -A INPUT -p icmp -j ACCEPT

# 5. 开放特定服务端口（按需添加）
iptables -A INPUT -p tcp --dport 22 -j ACCEPT    # SSH
iptables -A INPUT -p tcp --dport 80 -j ACCEPT    # HTTP
iptables -A INPUT -p tcp --dport 443 -j ACCEPT   # HTTPS


# 进入防火墙的数据包目的地址转换，从网口 eth0 进入的数据包，把目的 IP 为 114.115.116.117，端口为 80 的数据包，转到 10.0.0.1
# 这里外网用户访问公网地址 114.115.116.117:80，防火墙再转发到内网地址
iptables -t nat -A PREROUTING -i eth0 -d 114.115.116.117 -p tcp --dport 80 -j DNAT --to-destination 10.0.0.1

# 源地址转换，源地址 10.0.0.0/24 ，从网口 eth1 发出，并把源地址伪装成 111.112.113.114，响应回来后再转换为源地址
# 这里是内网地址 10.0.0.0/24 主机访问外网，会将内网地址伪装成公网 IP 111.112.113.114
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -i eth1 -j SNAT --to-source 111.112.113.114
```

**规则的顺序问题**：

- 规则的顺序很重要，**先匹配的规则先执行**。
- 如果没有匹配的规则，那么就会使用默认策略。

```bash
# 可以接收从 IP 为 10.0.0.1 发送的数据包
iptables -t filter -A INPUT -s 10.0.0.1 -j ACCEPT  

iptables -A INPUT -s 10.0.0.2 -j ACCEPT
iptables -A INPUT -s 10.0.0.2 -j DROP
```

INPUT 链配置了两条规则：
- 分别是接收 IP 为 `10.0.0.2` 的数据包；
- 和丢弃 IP 为 `10.0.0.2` 的数据包。

那么 `10.0.0.2` 的数据包能不能进来？

**可以**。数据包会先匹配前面的 `ACCEPT 10.0.0.2` 的规则，这个时候数据包就进入了系统，所以规则顺序很重要。**可以使用 `-I` 把规则从头插入**：

```bash
iptables -I INPUT -s 10.0.0.2 -j ACCEPT
```
