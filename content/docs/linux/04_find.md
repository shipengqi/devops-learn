---
title: 查找文件
weight: 4
---

## find

find 命令用来在指定目录下查找文件。格式：`find <文件路径> <查找条件> [补充条件]`。

```bash
[root@pooky ~]# find /etc -name pass*   # 查找 /etc 目录下 pass 前缀的文件
/etc/pam.d/passwd
/etc/pam.d/password-auth-ac
/etc/pam.d/password-auth
/etc/openldap/certs/password
/etc/passwd
/etc/selinux/targeted/active/modules/100/passenger
/etc/passwd-
[root@pooky ~]# find /etc -regex .*wd$  # 使用正则 -regex
/etc/security/opasswd
/etc/pam.d/passwd
/etc/passwd
[root@pooky ~]# find /etc -type f -regex .*wd$
/etc/security/opasswd
/etc/pam.d/passwd
/etc/passwd
```

常用参数：

- **`-name`：按文件名查找**（区分大小写）。
- `-iname`：按文件名查找（不区分大小写）。
- `-type`：按文件类型查找。`find /var -type d -name "log"` 在 `/var` 下查找所有名为 `log` 的目录。
  - `f`：普通文件 (file)。
  - `d`：目录 (directory)。
  - `l`：符号链接 (link)。
- **`-mtime`：按文件内容修改时间查找（天为单位）**，`find /var/log -name "*.log" -mtime -1`，查找 `/var/log` 下昨天到现在修改过的日志文件。
  - `-mtime +n`：n 天之前被修改过的文件。
  - `-mtime -n`：n 天之内被修改过的文件。
  - `-mtime n`：正好 n 天前被修改过的文件。
- `-mmin`：按文件内容修改时间查找（分钟为单位），`find /tmp -cmin -10` 查找 /tmp 下 10 分钟之内内容被修改过的文件。
- **`-atime/-amin`：按文件访问时间查找（天/分钟）**。
- `-ctime/-cmin`：按文件状态改变时间查找（如权限、属主）。
- **`-size`：按文件大小查找**，`find / -type f -size +100M` 在整个系统查找大于 100MB 的文件（常用于定位磁盘空间杀手）。
  - `-size +n`：大于 n 个指定单位的文件 `find /var/log -name "*.log" -size +1G` 查找超过 1G 的巨大日志文件。
  - `-size -n`：小于 n 个指定单位的文件。
  - 单位：c（字节），k（KB），M（MB），G（GB）。
- `-perm`：按文件权限查找。
  - `-perm 644`：查找权限正好是 644 的文件。
  - `-perm -644`：查找权限包含 644 的文件（如 755, 644 都匹配，因为都包含了 `rw-r--r--`）。
- `-user`：按文件属主查找，`find /home -user pooky` 查找属于用户 pooky 的所有文件。
- `-group`：按文件属组查找。

### 逻辑操作符

- `-a` 或 `-and`：与（默认操作符，可省略）。
- `-o` 或 `-or`：或。
- `!` 或 `-not`：非。
- **`()`：组合条件**，提高优先级。**括号需要被转义或引用**，如 `\( ... \)` 或 `'( ... )'`。

```bash
# 查找所有 .txt 或 .md 文件
find . \( -name "*.txt" -o -name "*.md" \)

# 查找所有不属于 root 用户的文件
find . ! -user root
```

### 执行操作

- `-exec`：对匹配的文件执行指定的命令。命令以 `;` 结束，`{}` 是查找结果的占位符。`;` 需要转义。
- `-ok`：与 `-exec` 类似，但在执行命令前会交互式地询问用户确认，更安全。
- `-delete`：直接删除匹配的文件。

```bash
# 查找并删除 /tmp 下所有 .tmp 文件
find /tmp -name "*.tmp" -exec rm -f {} \;
```

### 应用场景

```bash
# 清理 /tmp 下超过 7 天未访问的临时文件
find /tmp -type f -atime +7 -delete

# 清理 /var/log 下超过 30 天的日志文件（.log.gz 等压缩过的日志）
find /var/log -name "*.log*" -mtime +30 -delete

# 查找当前目录下大于 500MB 的文件，并按大小排序
find . -type f -size +500M -exec ls -lh {} \; | sort -k 5 -hr

# 查找所有 .conf 配置文件，并用 tar 打包备份
find /etc -name "*.conf" -exec tar -rvf backup.tar {} \;

# 将某个用户（如nginx）创建的所有文件属主改为 www-data
find /srv/www -user nginx -exec chown www-data:www-data {} \;

# 批量修改目录权限为 755，文件权限为 644
find /path/to/dir -type d -exec chmod 755 {} \;
find /path/to/dir -type f -exec chmod 644 {} \;

# 统计当前目录下 JavaScript 文件的数量
find . -name "*.js" | wc -l

# 忽略错误输出：在搜索根目录 / 时，会遇到大量权限拒绝的错误，干扰查看结果。可以将错误重定向到黑洞。
find / -name "something" 2>/dev/null
```

{{< callout type="warning" >}}
**先确认，再操作**：在使用 `-exec`、`-delete` 等具有破坏性的参数前，先用 `-print` 或 `-ls` 模拟运行一次，确认找到的文件是你要操作的目标。
{{< /callout >}}


## which

**在用户的 PATH 环境变量所指定的目录列表中，搜索某个可执行命令的完整路径**。

`which` 只找能直接运行的命令。

- `-a` 显示所有匹配的可执行文件路径，而不仅仅是第一个。

用 `which` 检查一下，如果没输出，说明该命令确实不在 PATH 中。

## whereis

在一个标准的 Linux 系统目录列表（如 `/bin`, `/usr/bin`, `/usr/local/bin`, `/usr/share/man` 等）中搜索某个命令的二进制文件（可执行文件）、源代码文件和 man 帮助手册文件。

- `-b` 只搜索二进制（可执行）文件。	`whereis -b nginx`。
- `-m` 只搜索手册页文件。`whereis -m ls`。
- `-s` 只搜索源代码文件。`whereis -s bash`。


