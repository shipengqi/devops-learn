---
title: NFS
weight: 10
---

NFS 在 Linux 中会默认安装。

## 配置文件

NFS 的主配置文件：`/etc/exports`。

```bash
[root@SGDLITVM0905 ~]# cat /etc/exports
/data/share *(rw,sync,all_squash)
/data/share2 10.222.77.0/24(rw,sync,insecure,no_subtree_check,no_root_squash)
/var/vols/itom/core *(rw,sync,anonuid=1999,anongid=1999,root_squash)
...
```

格式：

```bash
<共享的目录路径> <客户端IP或网段(选项1,选项2,...)>

# 共享 /data 目录给 192.168.1.0/24 网段，可读写，并压缩 root 权限
/data 192.168.1.0/24(rw,sync,root_squash)

# 共享 /backup 目录给特定 IP 192.168.1.100，只读，所有用户映射为 UID=1001 的用户
/backup 192.168.1.100(ro,all_squash,anonuid=1001,anongid=1001)
```

常用选项：

- `ro`：只读访问，共享静态数据，如软件包、配置文件。
- `rw`：读写访问，需要客户端写入数据的共享目录。
- `sync`：**同步写入，数据更安全，但性能较低（默认）**。请求完成后才写入磁盘。
- `async`：异步写入，性能更高，但风险更大。先响应请求，再写入磁盘。
- `no_root_squash`：信任 `root` 用户，**危险！客户端的 root 用户在服务端也拥有 root 权限**。
- `root_squash`：**安全！客户端的 root 用户被映射为服务端的匿名用户（nfsnobody）**。
- `all_squash`：**所有客户端用户都映射为匿名用户，适用于公共目录**。
- `anonuid/anongid`：**指定匿名 UID/GID 与 all_squash 配合，指定映射到的具体用户 ID 和组 ID**。

## 常用命令

```bash
# 使配置生效
# 通用命令（CentOS 7/8, Rocky Linux, AlmaLinux）
# -a：全部（export 所有 / 取消 export 所有）
# -r：重新 export（重新读取 `/etc/exports`）
# -v：显示详细信息
exportfs -arv

# 或者重启服务（较老系统）
systemctl restart nfs-server  # 或 nfs-kernel-server

# 查看当前共享状态
exportfs -v
showmount -e localhost # 查看本机共享了哪些目录

# 示例：查看192.168.1.10上共享的目录
showmount -e 192.168.1.10

# 临时挂载（重启后失效）
mount -t nfs <NFS_Server_IP>:/<shared_directory> /<local_mount_point>
# 示例：将服务端的 /data 挂载到本地的 /mnt/nfs_data
mount -t nfs 192.168.1.10:/data /mnt/nfs_data

# 永久挂载 （配置 /etc/fstab）
# 在 `/etc/fstab` 文件中添加一行，实现开机自动挂载。
# 添加配置后，执行 mount -a 命令来挂载所有在 fstab 中定义的文件系统，测试配置是否正确
# defaults，通用的选项集合，对于生产环境，可能会根据需要替换为更具体的选项，例如 rsize=8192,wsize=8192
# 第一个 0，这个字段被 dump 命令用来决定是否需要备份这个文件系统，0 表示：忽略，不备份
# 第二个 0，系统启动时，fsck 程序会用它来决定检查文件系统的顺序，0 表示：不检查。对于网络文
# 件系统（NFS）、虚拟文件系统或者非根磁盘，必须设置为0。根文件系统通常设置为1，表示优先检查。
<NFS_Server_IP>:/<shared_directory> /<local_mount_point> nfs defaults 0 0
# 示例：
192.168.1.10:/data /mnt/nfs_data nfs defaults 0 0

# 卸载NFS共享目录
umount /<local_mount_point>
# 示例：卸载 /mnt/nfs_data
umount /mnt/nfs_data

# 查看已挂载的NFS共享
mount -t nfs  # 只显示NFS类型的挂载
df -hT        # 显示所有文件系统，包括类型和挂载点
```

## root_squash 是什么？为什么会有 Permission denied？

`root_squash` 的作用：将客户端上使用 `root` 用户（`UID=0`）发出的所有请求，映射（“压缩”）到服务器上的一个非特权用户（通常是 `nobody` 或 `nfsnobody`）。

设计目的：**这是极其重要的安全措施。如果没有它，任何在客户端拥有 root 权限的用户都可以在 NFS 共享上以 root 身份为所欲为，完全绕过服务器上的文件权限检查，造成巨大的安全风险**。

触发场景：
- 你在客户端直接使用 `sudo` 或 `su root` 操作挂载点。
- 某个服务或进程以 `root` 身份运行并尝试写入 NFS。

简单来说：**`root_squash` 故意拒绝了客户端 root 用户的权限，以防止安全漏洞**。

例如：

```bash
# /etc/exports 配置如下
/nfs_share 192.168.1.0/24(rw,sync,root_squash)
```

1. 在客户端（`UID=0`）执行：`sudo touch /mnt/nfs/test_file`
2. 请求到达 NFS 服务器。
3. `root_squash` 机制将客户端的 `UID=0` 映射为服务器上的 `UID=65534`（`nobody` 用户）。
4. 服务器尝试以 `nobody` 用户的身份在 `/nfs_share` 目录创建文件。
5. 如果服务器上的 `/nfs_share` 目录不属于 `nobody` 用户，且也没有给“其他用户”（`others`）写权限，那么操作就会失败，并返回 Permission denied。

解决方案：

1. 在客户端使用合适的普通用户不要使用 `sudo` 或 `root` 用户来访问 NFS 挂载点。使用一个普通用户，并确保该用户在服务器端也有相应的权限。这通常需要统一UID/GID 或使用下一个方案。

2. 使用 `all_squash` 并指定固定用户（最常用、最安全）这是处理多个客户端、多个用户情况下的最佳实践。它将所有客户端用户（包括 `root`）都映射到服务器上的同一个特定用户。

```bash
# 在 NFS 服务器上
# 1. 创建一个专门用于 NFS 共享的用户（如果还没有）
sudo useradd -r -s /bin/false -M nfsuser

# 2. 查看它的 UID 和 GID（例如是 1001:1001）
id nfsuser

# 3. 将共享目录的所有者改为这个用户
sudo chown -R nfsuser:nfsuser /nfs_share
sudo chmod -R 755 /nfs_share # 或 775 如果需要组写权限

# 修改 /etc/exports，使用 all_squash 并明确指定 UID/GID
/nfs_share 192.168.1.0/24(rw,sync,all_squash,anonuid=1001,anongid=1001)

# 使配置生效
sudo exportfs -ra
```

现在，无论客户端用什么用户（`root` 还是普通用户）写文件，在服务器上都会显示为 `nfsuser` 用户创建的。由于目录所有者就是 `nfsuser`，写入自然成功。


## 常见问题

**连通性排查**：

```bash
# 1. 检查网络是否通
ping <NFS_Server_IP>

# 2. 检查 NFS 服务端口（2049）是否开放
telnet <NFS_Server_IP> 2049
```

**权限排查（最常见的问题）**：

问题：客户端无法写入文件，提示 Permission denied。

原因：服务端和客户端的用户 `UID/GID` 不匹配，或者 `/etc/exports` 选项配置过于严格（如 `root_squash`）。

排查：
  - 在客户端和服务端同时执行 `id <username>`，检查相同用户名的 UID 和 GID 是否一致。
  - 检查服务端共享目录的本地文件权限：`ls -ld /shared/directory`
  - 检查服务端 `/etc/exports` 的选项，是否使用了 `all_squash` 或 `root_squash`。

**挂载点排查**：

问题：挂载失败

```bash
# 查看详细的挂载错误信息
mount -v <NFS_Server_IP>:/data /mnt/nfs_data

# 查看系统日志，获取错误线索
tail -f /var/log/messages    # CentOS/RHEL
tail -f /var/log/syslog      # Ubuntu/Debian
```

**性能排查**：

问题：NFS 读写速度慢

- 尝试在挂载时使用 `async` 选项（牺牲安全性换取性能）。
- 检查网络带宽和延迟。
- 使用 `nfsiostat`（类似 `iostat`）工具查看 NFS 挂载点的 IO 性能指标。
