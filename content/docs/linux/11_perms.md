---
title: 用户和权限管理
weight: 11
---

## 用户管理

- `useradd`：
  - `useadd pooky`，添加用户，**默认情况下会自动创建同名 group**。
  - `-g`：`useradd -g group1 pooky`，添加用户并加入到用户组
  - `-M`：不要自动建立用户的登入目录。
  - `-r`：建立系统账号。
  - `-s`：指定用户登入后所使用的 shell。默认值为 `/bin/bash`。**`/bin/false` 禁止用户登录, 用户不会收到任何错误或提示信息**。**`/sbin/nologin` 当被用作用户的登录 shell 时，它会显示一条拒绝登录的消息（通常是一行文本），然后结束会话**。
- `id pooky`：验证用户是否存在
- `userdel`：删除用户
  - `userdel pooky` 删除用户 pooky。
  - `-r`：会删除用户的 home 目录
- `passwd`:  修改密码
  - `passwd pooky` 设置用户 pooky 的密码。
  - 只运行 `passwd` 命令，**不提供用户，就会修改当前用户的密码**。
- `usermod`：修改用户属性  
  - `-a`: 追加组，如果想要保留用户的组，并添加新组时使用。
  - `-d`：修改用户 home 目录，`usermod -d /hmoe/pookyh pooky` 把 pooky 的 home 目录改为 pookyh。
  - `-g`：修改用户组。`usermod -g group1 pooky` 将 pooky 的用户组改为 group1。

### 用户组

- `groupadd`：创建用户组
- `groupdel`：删除用户组

### 用户切换

- `su`：切换用户
  - `su - user1`，切换到 user1，`-` 表示同时切换用户环境。
  - `exit` 退回上个用户。
- `sudo`：以 root 身份执行命令。

### visudo

**`su` 切换到 root 需要使用密码**。如果普通用户想要使用 root 权限，就需要密码。这是有风险的。因此出现了 `sudo`。

**`sudo` 可以使 root 去权限，有针对性的给指定的普通用户权限，并且不需要密码**。使用 `sudo` 的前提是配置 `/etc/sudoers` 文件来授权。

`visudo` 用来编辑 `/etc/sudoers`：

```bash
## Allows people in group pooky to run all commands
# %pooky 表示 pooky 用户组，如果要表示 pooky 用户，则去掉 %
%pooky     ALL=(ALL)      ALL

## Without a password
%pooky     ALL=(ALL)      NOPASSWD: ALL

## Allows members of the users group to mount and unmount the cdrom as root
%users     ALL=/sbin/mount /mnt/cdrom, /sbin/unmount /mnt/cdrom

## Allows members of the usrs froup to shutdown this system
%users     localhost=/sbin/shutdown -h now
```

### 用户和用户组的配置文件

`/etc/passwd` 是用户的配置文件，竟然用的密码文件！！真正的密码在 `/etc/shadow` 文件中！！

```bash
# 用户名:是否需要密码验证:UID:GID:注释:用户 home 目录:用户登录使用的命令解释器
# root:x 中 x 表示此用户有密码
root:x:0:0:root:/root:/bin/bash

# /sbin/nologin 表示不允许登录
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
# ...
```

可以直接编辑这个文件来新建用户。比如添加一行 `user1:x:1000:1000::/home/user1:/bin/bash`，用户 home 目录需要手动创建。

可以修改 UID 来修改权限，比如**把 UID 改为 0，用户就会拥有 root 权限**。

`/etc/shadow` 保存用户和密码信息，此文件只有 root 用户可以浏览和操作。

```bash
# 用户名:加密的密码:
root:$6$PcVZ4yj4vlMjqmkL$RUHwggR7gPD0SnjTF1WnStHi2If0hSJnc4M/oVTfD0omJxVGhQgnQhBKRNPiwcBSeL72IerSphnEVdaomgjx./::0:99999:7:::
bin:*:17492:0:99999:7:::
daemon:*:17492:0:99999:7:::
# ...
```

`/etc/group` 是用户组配置文件：

```bash
# 用户组名:是否需要密码验证:GID:用户组中的用户列表
root:x:0:
bin:x:1:
daemon:x:2:
daemon2:x:3:bin,daemon2
# ...
```

## 文件权限

### 查看文件权限

`ls -l` 可以查看文件权限：

```bash
# - 表示普通文件
# rwxr-xr-x 这 9 个字符表示权限，
# 前面 3 个字符 rwx 表示当前用户的权限
# 中间 3 个字符 r-x 表示所属用户组的权限
# 后 3 个字符 r-x 表示其他用户的权限
-rwxr-xr-x.  1 root root   12059203 Jun 12  2019 renewCert
```

### 修改文件权限

`chmod`：修改文件，目录的权限。
  - `u`，用户，对应 `rwxr-xr-x` 这 9 个字符中的前三个字符。
  - `g`，用户组，对应 `rwxr-xr-x` 这 9 个字符中的中间三个字符。
  - `o`，其他用户，对应 `rwxr-xr-x` 这 9 个字符中的后面三个字符。
  - `a`，所有用户，默认。
  - `+`，增加权限。
  - `-`，删除权限。
  - `=`，设置权限。
  - `-R`，参数表示递归目录下所有文件和子目录。

```bash
chmod u+x file # file 所属用户增加执行权限
chmod 751 file # file 所属用户分配 rwx(7) 权限，所在组分配 rx(5) 权限，其他用户分配 x(1) 权限
chmod u=rwx,g=rx,o=x file # 上例的另一种形式
chmod =r file # 为所有用户分配读权限，也就是 a=r
chmod 444 file # 同上例
chmod a-wx,a+r file # 同上例
chmod -R u+r directory # 递归地给 directory 目录下所有文件和子目录的属主分配读的权限
chmod 4755 # 4 表示要设置 SetUID 位，755 是标准的权限设置
```

#### SetUID (SUID) 的作用是什么？

当一个可执行文件被设置了 SetUID 位后：任何用户在执行这个文件时，其**有效用户 ID** (Effective UID) 将在程序运行期间临时变更**为这个文件的所有者（user）的 ID**，而**不是执行它的用户的 ID**。

- `4 = SetUID` (Set User ID) 仅用二进制于可执行文件，执行者将具有该文件的所有者的权限。
- `2 = SetGID` (Set Group ID) 执行者将具有该文件的所属用户组的权限。
- `1 = SBIT` (Sticky Bit) 仅用于目录，用来阻止非文件的所有者删除文件，仅有自己和 root 才有权力删除。

例如：

```bash
-rwsr-xr-x 1 root root 63960 Feb  7  2023 /usr/bin/passwd

# SGID
# s 出现在用户组的 x 权限的位置，执行者将具有该文件的所属用户组的权限。
-rwxr-sr-x. 1 root mlocate 39832 Jan 30  2014 /usr/bin/mlocate*

# SBIT
# rwt 里的 t 就表示该文件仅 root 和自己可以删除
drwxrwxrwt.  14 root root 4096 Aug 18 20:11 tmp
```

权限位中的 `s`（在用户执行位的 `x` 位置上）。这个 `s` 就是 SetUID 位的可视化表示。它表示这个文件具有 SetUID 权限，并且所有者是 root。

1. 普通用户（如 alice）没有权限直接修改受保护的 `/etc/shadow` 文件（该文件只有 root 可写）。
2. 但当 alice 执行 `passwd` 命令时，由于 SetUID 位的存在，这个进程会临时获得 root 权限。
3. 此时，`passwd` 命令就可以以 root 身份去写入 `/etc/shadow` 文件，从而成功修改 alice 自己的密码。
4. 命令执行结束后，进程结束，临时获得的 root 权限也随之消失。

如果没有 SetUID 位，`passwd` 命令就会以普通用户 alice 的权限运行，尝试写入 `/etc/shadow` 时会被拒绝，导致密码修改失败。

重要提示：**如果文件所有者没有执行权限（`x`），当你设置 SetUID 位时，`ls -l` 会显示为大写的 `S`（例如 `rwSr-xr-x`），这表示 SetUID 位虽然设置了，但因为缺少执行权限，所以是无效的**。