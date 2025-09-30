---
title: firewalld
weight: 2
---

firewalld 的使用比 iptables 简单，主要区别：

- firewalld 使用区域和服务而不是链式规则。
- 它动态管理规则集，允许更新规则而不破坏现有会话和连接。

使用：

- `systemctl start|stop|enable|disbale firewalld.service` 控制 firewalld 服务。
- `firewqll-cmd` 是 firewalld 配置命令。

**iptables 和 firewalld 同时运行会产生冲突，应该关闭其中一个**。

```bash
# 查看状态
[root@shcCentOS72VM07 ~]# firewall-cmd --state

# 重新加载配置
[root@shcCentOS72VM07 ~]# firewall-cmd --reload

# 查看具体信息
[root@shcCentOS72VM07 ~]# firewall-cmd --list-all
public (active) # public 就是一个区域 zone
  target: default
  icmp-block-inversion: no
  interfaces: eth0
  sources: 10.0.0.1 10.0.0.1/24
  services: ssh dhcpv6-client
  ports: 80/tcp 23/tcp
  protocols:
  masquerade: no
  forward-ports:
  sources-ports:
  icmp-blocks:
  rich rules:

# 上面的输出表示 public zone 绑定了 eth0 网口，
# source IP 为 10.0.0.1 10.0.0.1/24 的请求可以访问 80 端口和 23端口，还可以访问 ssh 服务和 dhcpv6-client 服务。
[root@shcCentOS72VM07 ~]#  
```