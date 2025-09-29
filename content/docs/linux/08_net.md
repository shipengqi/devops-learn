---
title: 网络
weight: 8
---

net-tools 是 CentOS 7 之前的版本使用的网络管理工具，而 iproute2 是 CentOS 7 之后主推的网络管理工具。

net-tools 包括：
- ifconfig 网卡配置
- route 网关配置
- netstat 查看网络状态

iproute2 包括：
- ip：包含里 ifconfig 和 route 的功能
- ss：类似 netstat ，更快更强

## ip 命令

### ip addr 命令

ip addr 命令用于查看和管理网络接口的 IP 地址。

### ip route 命令

`ip route` 命令它不仅仅是用来“查看路由表”，更是操作 Linux 内核路由表的核心工具。

#### 什么是路由？

它是一套**双向**规则，既扮演着“迎宾员”的角色，决定如何接收外来数据包；也扮演着“导航员”的角色，决定如何发送外出数据包。

#### ip route 命令的角色
ip route 是 iproute2 软件套件的一部分，用于查看和管理内核中的路由表（Routing Table）。它的工作原理可以理解为**用户空间与内核空间之间的一个桥梁**：

1. 用户输入命令：例如 `ip route add 192.168.2.0/24 via 192.168.1.1`。
2. **内核系统调用**：通过 Netlink 套接字（一种专门用于内核与用户进程通信的机制）将“添加路由”的请求发送给 Linux 内核。
3. **内核处理请求**：内核网络栈接收到请求后，会根据请求参数（如目标网络、下一跳地址等）进行解析和处理。
4. **内核修改路由表**：内核网络栈接收到请求后，在其内部的路由表中创建、删除或修改相应的路由条目。
5. **生效**：此后，所有进出主机的数据包转发决策都将依据新的路由表进行。

#### 路由表的结构与查看

直接输入 `ip route show`（或简写为 `ip r`）可以查看当前的路由表。它的结构由一系列路由条目组成，每个条目包含以下几个关键部分：

| 部分 | 含义 | 示例 | 解释 |
| --- | --- | --- | --- |
| 目标网络 (Destination) | 数据包要去的IP网段 | 192.168.1.0/24 | 这条规则适用于去往 192.168.1.x 的所有包 |
| via (网关/Gateway) | 下一跳路由器的IP地址 | via 192.168.0.1 | 把数据包发给这个地址（路由器）去处理 |
| dev (接口/Device) | 数据包应该从哪个网络接口发出 | dev eth0 | 数据包从 eth0 网卡发出 |
| proto (协议/Protocol) | 此路由条目的来源 | proto kernel | 由内核自动生成（直连路由）|
| scope (作用域) | 路由的有效范围 | scope link | 仅适用于直连链路 | 
| metric (度量值) | 路由的优先级（成本）| metric 100 | 值越小，优先级越高 |

`ip route show` 示例：

```bash
default via 192.168.0.1 dev eth0 proto dhcp metric 100
192.168.0.0/24 dev eth0 proto kernel scope link src 192.168.0.100 metric 100
local 192.168.0.100 dev eth0 proto kernel scope host src 192.168.0.100
```

1. **默认路由 (Default Route)**：`default via 192.168.0.1 dev eth0 proto dhcp metric 100`。
   - 所有发往非本机、非直连网络的数据包（即不知道往哪扔的包），都通过 `eth0` 网卡发给网关 `192.168.0.1`。
   - **`default` 是 `0.0.0.0/0` 的简写**。
   - `proto dhcp` 表示这个路由是通过 DHCP 动态获取的。
   - `metric 100` 表示这个路由的优先级是 100，数值越小，优先级越高。
2. **直连路由 (Direct Route)**：`192.168.0.0/24 dev eth0 proto kernel scope link src 192.168.0.100 metric 100`。
   - 发往 `192.168.0.0/24` 这个网段的数据包，直接通过 `eth0` 网卡发出，不需要网关。`src` 指明了从本机发出数据包时，默认使用的源 IP 地址。
   - 当你为网卡配置 IP 地址并启动时（如 `ip addr add 192.168.0.100/24 dev eth0`），内核会自动生成对应的直连路由。
   - 意思就是，这个包是局域网内的包，不需要通过网关发送了，所以没有 `via`。
3. **本地路由 (Local Route)**：`local 192.168.0.100 dev eth0 proto kernel scope host src 192.168.0.100`。
   - 这条路由通常不会在 `ip route show` 中直接显示，需要使用 `ip route show table local` 查看。它管理发往本机自身 IP 的数据包。
   - `local`：关键字。明确标识这是一条本地路由，与普通路由的网段格式（如 `192.168.0.0/24`）不同。
   - `192.168.0.100`：目标地址。这就是本机配置的 IP 地址。它是一个精确的主机路由（`/32`），而不是一个网段。
   - **`scope host`：作用域。这是最关键的部分**！`scope host` 意味着这条路由**仅在本机内部有效，绝不可能被转发到网络上去**。它划清了一条清晰的边界：这是“我自己”。

dev lo：关联接口。这个 IP 地址被配置在 lo 接口上。

proto kernel：协议。由内核自动生成。

scope host：作用域。这是最关键的部分！scope host 意味着这条路由仅在本机内部有效，绝不可能被转发到网络上去。它划清了一条清晰的边界：这是“我自己”。

#### 路由查询过程

当内核需要发送一个数据包时，是如何使用这张表的呢？这个过程称为**路由查找** (Route Lookup)，它遵循**最长前缀匹配 (Longest Prefix Match) 原则**：

1. **数据包目标 IP**：例如 `192.168.0.150`。
2. **查询路由表**：内核逐条比对路由条目中的“目标网络”。
3. **匹配**：
   - 它会同时匹配 `192.168.0.0/24` (24 位前缀) 和 `default / 0.0.0.0/0` (0 位前缀)。
   - 根据最长前缀匹配原则，`/24` 比 `/0` 更具体、更长，因此优先级更高。
4. **执行**：内核选择 `192.168.0.0/24 dev eth0` 这条路由，直接将数据包从 `eth0` 接口发出，而无需经过网关。

#### 常用命令示例及其原理

| 命令示例 | 工作原理 |
| --- | --- |
| `ip route add default via 192.168.1.1` | 添加默认路由。将所有未知流量导向网关 `192.168.1.1`。 |
| `ip route add 10.1.0.0/16 via 192.168.1.2` | 添加静态路由。将所有去往 `10.1.0.0/16` 的流量交给下一跳路由器 `192.168.1.2`。 |
| `ip route del 10.1.0.0/16` | 删除一条静态路由。 |
| `ip route replace default via 192.168.1.254` | 替换现有默认路由。将默认网关从之前的改为 `192.168.1.254`。 |
| `ip route get 8.8.8.8` | 模拟路由查询，诊断“网络不通”问题。显示内核是如何路由到 `8.8.8.8` 的，用于调试。 |

## ss 命令

属于 iproute2 工具包，类似 netstat，参数类似，显示格式不同。

两者的区别：

- 性能：ss 直接从内核空间获取信息，速度极快。而 **netstat 会遍历 `/proc/net` 下的文件，在连接数非常多时（如数万）速度很慢**。
- 信息更丰富：ss 可以显示更多的 TCP 内部状态信息（如拥塞控制、内存使用等）。

格式为：`ss [选项] [过滤器]`

- `-t`：显示 TCP sockets。`ss -t`。
- `-u`：显示 UDP sockets。`ss -u`。
- `-l`：显示正在监听（Listen）的 sockets。`ss -tl`。
- `-a`：显示所有 sockets（包括监听和非监听）。`ss -ta`。
- `-n`：不解析服务名称（显示端口号而不是像“http”这样的名字）。强烈推荐始终使用，速度更快且信息更准确。`ss -tn`。
- `-p`：显示使用 socket 的进程信息（需要 sudo）。`sudo ss -tp`。
- `-4`：仅显示 IPv4 sockets。`ss -t4`。
- `-6`：仅显示 IPv6 sockets。`ss -t6`。

过滤选项:

- `sport = :端口号`：过滤源端口。`ss sport = :80`
- `dport = :端口号`：过滤目标端口。`ss dport = :443`
- `src IP地址`：过滤源 IP 地址。`ss src 192.168.1.100`
- `dst IP地址`：过滤目标 IP 地址。`ss dst 8.8.8.8`
- `state`：过滤连接状态。`ss state established`

输出选项:

- `-e`：显示详细的 socket 信息（如 UID、内存等）。`ss -te`。
- `-o`：显示 TCP 计时器信息（如 TCP 重传超时）。`ss -to`。
- `-i`：显示 TCP 内部信息（拥塞控制、流量控制）。`ss -ti`。
- `-m`：显示 socket 的内存使用情况。`ss -tm`。
- `-s`：打印摘要统计信息（**非常有用**）。`ss -s`。

### 使用场景

用于检查哪些端口已开放并正在等待连接：

```bash
sudo ss -tunlp
# -t: TCP, -u: UDP, -n: 不解析, -l: 监听, -p: 显示进程
# 输出
# 一眼就能看出：Nginx（PID 1234）在监听 80 端口，SSH（PID 5678）在监听 22 端口
Netid State  Recv-Q Send-Q Local Address:Port Peer Address:Port
tcp   LISTEN 0      128          *:80              *:*      users:(("nginx",pid=1234,fd=6))
tcp   LISTEN 0      128          *:22              *:*      users:(("sshd",pid=5678,fd=3))
```

```bash
# 查看所有活跃的网络连接
ss -tna | grep ESTAB
# 或者更精确地，查看所有已建立连接
ss -t state established
```

当服务器出现性能问题或怀疑连接数过多时：

```bash
ss -s
# 输出列解读：
Total: 1234 (kernel 0)
# TCP 行：可以快速了解当前连接状态分布（已建立、关闭、等待释放等）
TCP:   1456 (estab 234, closed 1100, orphaned 5, timewait 1100)
Transport Total     IP        IPv6
*         0         -         -
RAW       1         0         1
UDP       20        18        2
TCP       356       350       6
INET      377       368       9
FRAG      0         0         0
```

排查特定服务或端口的问题：
```bash
# 1. 查看谁在连接我的MySQL服务（3306端口）
ss -tn dst :3306

# 2. 查看我的Web服务器（80端口）正在与哪些客户端建立连接
ss -tn src :80

# 3. 查看某个IP地址（如 192.168.1.15）与我的所有连接
ss -tn dst 192.168.1.15

# 分析TCP连接内部状态
# 显示TCP连接的详细状态，包括计时器信息（重传超时等）
ss -tno

# 显示更详细的内部信息，包括拥塞窗口、往返时间等
ss -tni
```

## 网络诊断

### 如何查看到目标主机的网络状态

1. 使用 `ping <IP 或者 域名>` 查看网络是否是通的。
2. `traceroute` 和 `mtr` 辅助 `ping` 命令，在 `ping` 通网络之后，如果网络通信还是有问题，
   - 可以使用 `traceroute` 可以查看网络中每一跳的网络质量。
   - `mtr` 可以检测网络中是否有丢包。
- `nslookup` 查看域名对应的 IP。
- 如果主机可以连接，但是服务仍然无法访问，使用 `telnet` 检查端口状态。
- 如果端口没有问题，仍然无法访问，可以使用 `tcpdump` 进行抓包，更细致的查看网络问题。
- 使用 `netstat` 和 `ss`，查看服务范围。

### traceroute

`traceroute -w 1 www.baidu.com`，

- `-w` 等待响应的超时时间，单位为秒，`-w 1` 表示某个 IP 超时的最大等待时间为 1 秒。
- `-n` 显示 IP 地址
- `-m` 设置最大跳数，默认 64。
- `-q` 每个网关发送数据包个数，默认 3。
- `-p` 指定使用的目标端口。
- `-I`，`--icmp` 使用 ICMP ECHO 作为探测包。
- `-M`，`--type=Method` 指定使用的探测方法（`icmp` 或者 `udp`），默认 `udp`。

```bash
[root@shcCDFrh75vm8 ~]# traceroute -w 1 www.baidu.com
traceroute to www.baidu.com (104.193.88.77), 30 hops max, 60 byte packets
 1  gateway (16.155.192.1)  0.525 ms  0.635 ms  0.800 ms
 2  10.132.24.193 (10.132.24.193)  0.600 ms  0.930 ms  1.137 ms
 3  192.168.201.122 (192.168.201.122)  0.826 ms  0.746 ms  0.674 ms
 4  192.168.200.45 (192.168.200.45)  2.045 ms  1.978 ms  1.962 ms
 5  192.168.203.249 (192.168.203.249)  29.375 ms  29.351 ms  29.275 ms
 6  192.168.203.250 (192.168.203.250)  3.892 ms  2.980 ms  2.907 ms
 7  192.168.200.185 (192.168.200.185)  68.675 ms  68.636 ms  68.691 ms
 8  192.168.200.186 (192.168.200.186)  70.094 ms  70.356 ms  69.995 ms
 9  * * *
10  * * * # * 表示不支持 traceroute 追踪。
11  * * *
12  * * *
13  * * *
14  * * *
15  * * *
16  * * *
17  * * *
18  * * *
19  * * *
```

记录按序列号从 1 开始，每个纪录就是一跳 ，每跳表示一个网关，可以看到每行有三个时间，单位是 ms，之所以是 3 个，其实就是 `-q` 的默认参数。

探测数据包向每个网关发送三个数据包后，记录网关响应后返回的时间。

### mtr

运行 `mtr` 可以查看更详细的网络状态：

| 类别         | 参数          | 作用             | 示例                      |
| ---------- | ----------- | -------------- | ----------------------- |
| **协议/端口**  | `-T`        | TCP SYN 探测     | `mtr -T -P 443 1.1.1.1` |
|            | `-u`        | UDP 探测         | `mtr -u -P 53 8.8.8.8`  |
|            | `-P`        | 指定目标端口         | `mtr -T -P 443 1.1.1.1` |
| **输出格式**   | `-n`        | 不解析主机名（纯 IP）   | `mtr -n 8.8.8.8`        |
|            | `-r`        | 报告模式（一次性统计）    | `mtr -r 8.8.8.8`        |
|            | `-c <N>`    | 发送 N 次探测后结束    | `mtr -r -c 100 8.8.8.8` |
| **时间控制**   | `-i <s>`    | 每次探测间隔（秒）      | `mtr -i 0.5 8.8.8.8`    |
|            | `-p <s>`    | 同 `-i`（兼容写法）   | `mtr -p 0.5 8.8.8.8`    |
| **TTL/跳数** | `-m <N>`    | 最大跳数（默认 30）    | `mtr -m 50 8.8.8.8`     |
| **调试/帮助**  | `-4` / `-6` | 强制 IPv4 / IPv6 | `mtr -4 8.8.8.8`        |
|            | `-h`        | 查看全部选项         | `mtr -h`                |


`mtr -n baidu.com` 输出示例：

```bash
                                                 My traceroute  [v0.95]
DESKTOP-DMAGDPE (172.18.149.141) -> bdidu.com (76.223.54.146)                                  2025-08-27T15:34:02+0800
Keys:  Help   Display mode   Restart statistics   Order of fields   quit
                                                                               Packets               Pings
 Host                                                                        Loss%   Snt   Last   Avg  Best  Wrst StDev
 1. 172.18.144.1                                                              0.0%     9    0.6   0.7   0.2   1.5   0.4
 2. 192.168.31.1                                                              0.0%     9    2.1   2.5   1.5   4.2   1.0
 3. 192.168.1.1                                                               0.0%     9    4.0   3.3   2.1   4.0   0.6
 4. 100.84.128.1                                                              0.0%     9    6.4   8.7   5.4  19.5   4.2
 5. (waiting for reply)
 6. (waiting for reply)
 7. (waiting for reply)
 8. (waiting for reply)
 9. 219.158.3.214                                                            50.0%     9   30.4  31.1  30.2  32.7   1.2
10. 219.158.3.102                                                            33.3%     9   62.7  61.7  60.3  62.7   0.9
11. 219.158.34.230                                                            0.0%     9   86.4  88.9  85.4 107.6   7.6
12. (waiting for reply)
13. (waiting for reply)
14. (waiting for reply)
15. 52.93.8.41                                                                0.0%     8   95.2  94.8  92.7  99.4   2.2
16. 52.93.8.18                                                                0.0%     8   86.7  87.8  85.8  94.2   2.9
17. 76.223.54.146                                                             0.0%     8   85.9  86.3  84.9  88.5   1.1

```

`mtr` 输出列解读：

- `Loss%`：丢包率。这是**最重要的指标**，某一跳的丢包率突然升高，通常意味着该节点或链路有问题。
- `Host`：主机名或 IP 地址。
- `Snt`：发送的探测包数量。
- `Last`：最近一次的延迟（毫秒）。
- `Avg`：平均延迟（毫秒）。
- `Best`：最佳延迟（毫秒）。
- `Wrst`：最差延迟（毫秒）。
- `StDev`：延迟抖动（标准方差）。这个值越大，说明网络越不稳定。

#### 使用场景

```bash
# 精确定位网络丢包和抖动问题（最核心的场景）
# 运行后，观察哪一跳的 Loss% 开始出现并持续存在（而不是仅在最后一跳），这里就是问题点。
mtr -n baidu.com

# 向目标发送100个包后生成报告
# 网络不稳定时，运行一段时间（几分钟）的 mtr，将报告保存下来，作为向运营商报障的有力证据。
mtr -r -c 100 -n example.com > mtr_report.log

# 只显示最重要的列：丢包率、平均延迟、最佳延迟、最差延迟
mtr -r -c 50 -o "L ABW" -n 203.0.113.10
```

**有些网络设备会限速或优先处理数据包而非 ICMP 应答，导致中间节点显示丢包，但最终目标不丢包**。这就需要经验来判断是真实丢包还是设备策略。

### 运维工作流

```bash
# 1. 使用 mtr 进行初步诊断，定位问题范围
# 使用 --tcp 和 -p 443 是为了模拟真实的 HTTPS 流量，更有可能穿透防火墙
# 观察几十秒到一分钟
# 发现：在第 8 跳（某个国际出口路由器）之后，Loss% 上升到 15%，Wrst 延迟超过 500ms。
mtr -n --tcp -p 443 example.com

# 2. 使用 traceroute 快速确认路径
traceroute -n -p 443 example.com

# 3. 得出结论并提供证据
# 问题出在出国链路的第 8 跳节点附近，存在严重丢包和高延迟。
# 保存 mtr 报告截图或文本
```

- **mtr 是绝大多数情况下的首选**。当你需要诊断网络慢、抖动、断线等质量问题时，优先使用 mtr。它能提供持续的数据，让你清晰看到丢包和延迟发生在哪一跳。
- 当你只需要快速看一眼路由路径是否正常，或者在脚本中调用时，使用 traceroute。它的输出更简单，更适合自动化处理。

### tcpdump

```bash
tcpdump -i any

07:02:12.195611 IP test.ya.local.59915 > c2.shared.ssh: Flags [.], ack 1520940, win 2037, options [nop,nop,TS val 1193378555 ecr 428247729], length 0
07:02:12.195629 IP c2.shared.ssh > test.ya.local.59915: Flags [P.], seq 1520940:1521152, ack 1009, win 315, options [nop,nop,TS val 428247729 ecr 1193378555], length 212
07:02:12.195677 IP test.ya.local.59915 > c2.shared.ssh: Flags [.], ack 1521152, win 2044, options [nop,nop,TS val 1193378555 ecr 428247729], length 0
07:02:12.195730 IP c2.shared.ssh > test.ya.local.59915: Flags [P.], seq 1521152:1521508, ack 1009, win 315, options [nop,nop,TS val 428247730 ecr 1193378555], length 356
```

- `-i`：**指定网卡，`any` 表示任意网卡**。如果只需要查看某个网卡的数据包，例如 `ehh0`，使用 `tcpdump -i eth0`。

#### 过滤主机

如果只想查看 ip 为 `10.211.55.2` 的网络包，这个 ip 可以是源地址也可以是目标地址：

```bash
tcpdump -i any host 10.211.55.2
```

#### 过滤源地址、目标地址

只抓取源地址是 `10.211.55.11` 的包：

```bash
tcpdump -i any src 10.211.55.11
```

只抓取目标地址为 `10.211.55.11` 的包：

```bash
tcpdump -i any dst 10.211.55.11
```

#### 过滤端口

只抓取某个端口的数据包，比如查看 80 端口的数据包：

```bash
tcpdump -i any port 80
```

只想抓取目标端口为 80 的数据包，也就是 80 端口收到的包，可以加上 `dst`：

```bash
tcpdump -i any dst port 80
```

#### 过滤指定端口范围内的流量

抓取 21 到 23 区间所有端口的流量：

```bash
tcpdump portrange 21-23
```

#### 禁用主机与端口解析

不加 `-n` 选项，tcpdump 会显示主机名，比如下面的 `test.ya.local` 和 `c2.shared`：

```bash
09:04:56.821206 IP test.ya.local.59915 > c2.shared.ssh: Flags [P.], seq 397:433, ack 579276, win 2048, options [nop,nop,TS val 1200089877 ecr 435612355], length 36
```

加上 `-n` 选项以后，可以看到主机名都已经被替换成了 ip：

```bash
tcpdump -i any  -n
10:02:13.705656 IP 10.211.55.2.59915 > 10.211.55.10.ssh: Flags [P.], seq 829:865, ack 1228756, win 2048, options [nop,nop,TS val 1203228910 ecr 439049239], length 36
```

**常用端口还是会被转换成协议名**，比如 ssh 协议的 22 端口。如果不想 tcpdump 做转换，可以加上 `-nn`，这样就不会解析端口了，输出中的 ssh 变为了 22：

```bash
tcpdump -i any  -nn

10:07:37.598725 IP 10.211.55.2.59915 > 10.211.55.10.22: Flags [P.], seq 685:721, ack 1006224, win 2048, options [nop,nop,TS val 1203524536 ecr 439373132], length 36
```

#### 过滤协议

只查看 udp 协议：

```bash
tcpdump -i any -nn udp

10:25:31.457517 IP 10.211.55.10.51516 > 10.211.55.1.53: 23956+ A? www.baidu.com. (31)
10:25:31.490843 IP 10.211.55.1.53 > 10.211.55.10.51516: 23956 3/13/9 CNAME www.a.shifen.com., A 14.215.177.38, A 14.215.177.39 (506)
```

#### 输出 ASCII 格式

`-A` 用 ASCII 打印报文内容：

```bash
tcpdump -i any -nn port 80 -A

11:04:25.793298 IP 183.57.82.231.80 > 10.211.55.10.40842: Flags [P.], seq 1:1461, ack 151, win 16384, length 1460
HTTP/1.1 200 OK
Server: Tengine
Content-Type: application/javascript
Content-Length: 63522
Connection: keep-alive
Vary: Accept-Encoding
Date: Wed, 13 Mar 2019 11:49:35 GMT
Expires: Mon, 02 Mar 2020 11:49:35 GMT
Last-Modified: Tue, 05 Mar 2019 23:30:55 GMT
ETag: W/"5c7f06af-f822"
Cache-Control: public, max-age=30672000
Access-Control-Allow-Origin: *
Served-In-Seconds: 0.002
```

#### 限制包大小

当包体很大，可以用 `-s` 截取部分报文内容，一般和 `-A` 一起使用。

```bash
# 查看每个包体前 500 字节
tcpdump -i any -nn port 80 -A -s 500
```

显示包体所有内容，可以加上 `-s 0`。

#### 只抓取 5 个报文

**使用 `-c number` 命令可以抓取 number 个报文后退出**。

```bash
tcpdump -i any -nn port 80  -c 5
```

#### 输出到文件

```bash
tcpdump -i any port 80 -w test.pcap
```

生成的 pcap 文件就可以用 wireshark 打开进行更详细的分析。

#### 显示绝对序号

默认情况下，tcpdump 显示的是从 0 开始的相对序号。如果想查看真正的绝对序号，可以用 `-S` 选项。

```bash
# 没有 -S
tcpdump -i any port 80 -nn

12:12:37.832165 IP 10.211.55.10.46102 > 36.158.217.230.80: Flags [P.], seq 1:151, ack 1, win 229, length 150
12:12:37.832272 IP 36.158.217.230.80 > 10.211.55.10.46102: Flags [.], ack 151, win 16384, length 0

# 加了 -S 
tcpdump -i any port 80 -nn -S 

12:13:21.863918 IP 10.211.55.10.46074 > 36.158.217.223.80: Flags [P.], seq 4277123624:4277123774, ack 3358116659, win 229, length 150
12:13:21.864091 IP 36.158.217.223.80 > 10.211.55.10.46074: Flags [.], ack 4277123774, win 16384, length 0
```

#### 运算符

tcpdump 可以用布尔运算符 `and`（`&&`）、`or`（`||`）、`not`（`!`）来组合出任意复杂的过滤器。

```bash
# 抓取 ip 为 10.211.55.10 并且目的端口为 3306 的数据包
tcpdump -i any host 10.211.55.10 and dst port 3306

# 抓取源 ip 为 10.211.55.10，目标端口除了 22 以外所有的流量
tcpdump -i any src 10.211.55.10 and not dst port 22
```

#### 分组

如果要抓取：来源 ip 为 `10.211.55.10` 且目标端口为 3306 或 6379 的包，如果按照下面的方式写，就会报错：

```bash
tcpdump -i any src 10.211.55.10 and (dst port 3306 or 6379)
```

因为 `()` 是不允许的。这时候可以使用单引号 `'` 把复杂的组合条件包起来：

```bash
tcpdump -i any 'src 10.211.55.10 and (dst port 3306 or 6379)'
```

##### 显示所有的 RST 包

```bash
tcpdump 'tcp[13] & 4 != 0'
```

TCP 首部中 offset 为 13 的字节的第 3 比特位就是 RST。`tcp[13]` 表示 tcp 头部中偏移量为 13 字节。`!=0` 表示当前 bit 置 1，即存在此标记位，跟 4 做与运算是因为 RST 在 TCP 的标记位的位置在第 3 位(00000100)。

##### 过滤 SYN + ACK 包

```bash
tcpdump 'tcp[13] & 18 != 0'
```

