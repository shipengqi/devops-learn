---
title: 打包压缩
weight: 2
---

Linux 里面打包和压缩是分开的两个命令 tar 和 gzip/bzip2。

## tar

- `tar -cf <压缩文件> <多个目录或文件>`
  - `-c` `--create` 打包
  - `-f` 指定归档文件。**总是用 -f 参数指定文件名，并放在参数集的最后**。
- `tar -xf <压缩文件>`
  - `-x` `--extract` 解压
- `tar -xf /tmp/backup.tar -C /root`： 把 `/tmp/backup.tar` 文件还原到 `/root` 目录下。
  - `-C` 解压到指定目录
- `tar -cf - /etc`： **`-` 表示压缩到标准输出。直接输出到标准输出没什么用，需要配合 `|`**：
  - 远程备份：`tar -cf - /data | ssh user@host "cat > backup.tar"`，无临时文件，高效流式传输
  - 流式压缩：`tar -cf - /data | gzip > backup.tar.gz`，灵活选择压缩工具和参数。
  - 内容检查：`tar -cf - /data | tar -t -f -`，不解压到磁盘即可查看内容。
  - 计算校验和：`tar -cf - /data | md5sum`，直接计算归档包的哈希值。
  - 加密：`tar -cf - /data | gpg -c > backup.tar.gpg`，边打包边加密，提升安全性

{{< callout type="info" >}}
`tar -c /etc` 和 `tar -cf - /etc` 类似，不同的是没有使用 `-f` 指定归档文件。一般默认的行为也是输出到标准输出。但是有一些历史版本不是的。这条命令的行为是隐式且**可能变化**的。
{{< /callout >}}

其他常用参数：

- `-t` `--list`  列出归档文件中的内容列表。例如 `tar -tf t.tar`。
- `-z` gzip 压缩，`tar.gz` 或者 `tgz`。需要解压缩就加上 `-z` 参数。例如 `tar -czf /tmp/backup.tar.gz /etc`。`tgz` 是 `.tar.gz` 的简写。
- `-j` bzip2 压缩，后缀 `tar.bz2` 或者 `tbz2`。需要解压缩就加上 `-j` 参数。例如 `tar -cjf /tmp/backup.tar.bz2 /etc`。`tbz2` 是 `.tar.bz2` 的简写。
- `-v` `--verbose`：显示指令执行过程。
- `--exclude`	排除不需要打包的文件或目录。

{{< callout type="info" >}}
- **`tar` 命令默认会打包所有文件，包括隐藏文件**（以点 `.` 开头的文件和目录）。
- `tar -czvf backup_with_star.tar.gz *` 不会打包隐藏文件，因为 **shell 会先将 `*` 扩展为所有非隐藏的文件名**。
- `gzip`、`bzip2` 压缩，`gzip` 压缩更快，`bzip2` 压缩比例更高。
{{< /callout >}}

### 应用场景

`tar -cf - /etc`：`-` 表示将 `tar` 压缩包写入到标准输出，而不是写入文件。


```bash
# 将 /etc 目录打包并用 gzip 压缩，保存为当前目录下的 etc-backup.tar.gz
tar -czvf etc-backup.tar.gz /etc/

# 使用更现代的 zstd 压缩，速度更快
tar -c --zstd -vf app-backup.tar.zst /var/www/myapp/

# 备份网站目录，但排除日志文件和缓存目录
tar -czvf site-backup.tar.gz \
    --exclude='*.log' \
    --exclude='./cache' \
    /var/www/html/

# 使用文件列表来排除
tar -czvf backup.tar.gz -X exclude-list.txt /data/
# exclude-list.txt 内容：
# *.tmp
# logs/
# temp/    


# 不需要特殊参数，tar 默认会保留权限、所有权和时间戳。
# 但在解压时，如果用普通用户解压，所有权信息会丢失（除非是 root）。
# 备份根目录 / 时要小心使用 --exclude 排除虚拟文件系统。
sudo tar -czvf full-system-backup.tar.gz --exclude=/proc \
--exclude=/sys --exclude=/dev --exclude=/tmp --exclude=/run \
--exclude=/mnt --exclude=/media /

# 列出 backup.tar.gz 里所有的文件
tar -tzvf backup.tar.gz

# 查找压缩包里是否包含某个配置文件
tar -tzvf backup.tar.gz | grep nginx.conf

# 将本地目录打包压缩后，直接通过 SSH 传输到远程服务器保存
tar -czv /data/ | ssh user@backup-server "cat > /backup/server-data-$(date +%F).tar.gz"

# 或者直接在远程服务器上解压
tar -czv /data/ | ssh user@backup-server "tar -xz -C /remote/backup/dir/"

# 打包过去 7 天内修改过的 .log 文件
find /var/log -name "*.log" -mtime -7 -exec tar -rvf weekly-logs.tar {} \;
# 然后再压缩
gzip weekly-logs.tar
```

{{< callout type="info" >}}
`tar -czv /data/ | ssh user@backup-server "cat > /backup/server-data-$(date +%F).tar.gz"` 使用 `cat > ` 的原因：

`>` 是 shell 的一个操作符，它的作用是将它左边命令的标准输出，重定向到右边的文件。**不会主动去读取它自己的标准输入**（stdin）。
{{< /callout >}}


