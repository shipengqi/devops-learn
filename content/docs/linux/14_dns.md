---
title: DNS
weight: 14
---

## dig

```bash
dig example.com
# 或者指定记录类型
dig A example.com
dig MX example.com   # 查询邮件服务器
dig NS example.com   # 查询权威DNS服务器
dig TXT example.com  # 查询TXT记录（常用于验证、SPF等）

# 使用Google的公共DNS查询，验证解析是否正确
dig @8.8.8.8 example.com

# 查询公司内部的DNS服务器，看内部解析是否正常
dig @192.168.1.10 example.com

# 直接向域名的权威DNS服务器查询，得到最准确的结果
dig @ns1.cloudflare.com example.com

# 反向DNS解析：通过IP地址查询域名（PTR记录）。
dig -x 8.8.8.8
```

## nslookup

```bash
# 直接查询
nslookup example.com

# 指定DNS服务器查询
nslookup example.com 8.8.8.8

# 进入交互模式（适合连续查询）
nslookup
> server 8.8.8.8  # 设置要查询的DNS服务器
> set type=MX     # 设置查询记录类型
> google.com      # 执行查询
> exit            # 退出
```

## /etc/resolv.conf

`/etc/resolv.conf` 文件的主要作用是配置系统使用的 DNS 解析器（Resolver）。它告诉系统：

1. 应该向哪些 DNS 服务器发送查询请求。
2. 如何对待本地域名（short name）。
3. 查询的搜索域（search domain） 顺序。

例如：

```bash
# 完整配置
# This file is managed by man:systemd-resolved(8). Do not edit.
# 或者是由 NetworkManager、DHCP 客户端管理的提示

# 指定DNS服务器
nameserver 192.168.1.1
nameserver 8.8.8.8

# 指定搜索域
search mydomain.com internal.mydomain.com

# 解析器选项
options timeout:2 attempts:2
```

- `nameserver`：指定 DNS 服务器地址：
  - 最多可以指定 3 个 nameserver，系统会按顺序尝试查询。
  - 建议至少配置两个，以保证高可用性。
  - 可以指向公共 DNS（如 `8.8.8.8`）、本地网络中的 DNS 服务器（如路由器 `192.168.1.1`）或自己搭建的 DNS 缓存服务器。

```bash
nameserver 192.168.1.1       # 本地路由器/网关
nameserver 8.8.8.8           # Google 公共 DNS（主）
nameserver 1.1.1.1           # Cloudflare 公共 DNS（备）
```

- `domain/search`：指定搜索域。这两个指令用于配置不完全限定域名（非 FQDN）的搜索方式。当你输入 `ping web01` 而不是 `ping web01.example.com` 时，系统会根据这个设置自动尝试补全域名。
  - `domain`：指定本地主机的域名。系统会尝试将主机名补全为 `<主机名>.<domain>`。
  - `search`：指定一个域名搜索列表（最多 6 个域，总长度限制）。系统会按顺序依次尝试补全。
  - **`domain` 和 `search` 不能同时使用；如果同时存在，则最后出现的一个生效**。

```bash
# 场景：你的服务器主机名是 server01，完整域名是 server01.prod.example.com
# 你想直接 ping 同一域下的其他主机，如 db01

search prod.example.com example.com
# 当你执行 `ping db01` 时，系统会依次尝试解析：
# 1. db01.prod.example.com
# 2. db01.example.com
# 3. db01 (最终失败)

domain prod.example.com
# 效果与 `search prod.example.com` 基本相同
```

- `options`配置解析器选项：
  - `options rotate`：在列出的多个 nameserver 之间进行轮询，而不是严格按顺序尝试。这可以实现简单的负载均衡。
  - `options timeout:n`：设置等待 DNS 服务器响应的超时时间（n 为秒数，默认通常为 5）。
  - `options attempts:n`：设置尝试查询每个 DNS 服务器的次数（默认通常为 2）。
