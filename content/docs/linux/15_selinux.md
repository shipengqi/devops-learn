---
title: SELinux
weight: 15
---


SELinux 会有三种模式：

- `enforcing`：强制模式。违反 SELinux 规则的行为将被阻止并记录到日志中。
- `permissive`：宽容模式。违反 SELinux 规则的行为只会记录到日志中。一般为调试用。
- `disabled`：关闭 SELinux。

可以在配置文件 `/etc/selinux/config` 中配置 SELINUX 的字段。

```bash
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=permissive
# SELINUXTYPE= can take one of three two values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected.
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
```

SELINUXTYPE 是 SELinux 的策略类型。有三种策略，分别是：

- `targeted`：**对大部分网络服务进程进行管制。系统默认**。
- `minimum`：以 `targeted` 为基础，仅对选定的网络服务进程进行管制。一般不用。
- `mls`：多级安全保护。对所有的进程进行管制。这是最严格的策略，配置难度非常大。一般不用。