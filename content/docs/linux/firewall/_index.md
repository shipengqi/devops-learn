---
title: 防火墻
weight: 88
---

防火墙分为两类：

- **软件防火墙**，CentOS 6 的默认防火墙是 **iptables**，CentOS 7 的默认防火墙是 **firewalld**，底层都是使用内核中的 `netfilter`实现的。
  - **包过滤防火墙**，主要用于数据包的过滤，数据包转发。
  - **应用层防火墙**，可以控制应用程序的具体的行为。
- **硬件防火墙**，例如 Cisco ASA、 Juniper SRX 等。