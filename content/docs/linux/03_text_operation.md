---
title: 操作文本
weight: 3
---

文本搜索一般会使用正则表达式。

## 元字符

常用的元字符：

- `.` 匹配除了换行符外的任意一个字符
- `*` 匹配任意个跟它前面的字符
- **`[]` 匹配方括号中的字符类中的任意一个**，比如 `[Hh]ello` 就可以匹配 hello 和 Hello。
- `^` 匹配开头
- `$` 匹配结尾
- `\` 转义字符

扩展元字符：

- `+` 匹配前面的正则表达式至少出现一次
- `?` 匹配前面的正则表达式出现一次或者零次
- `|` 匹配前面或者后面的正则表达式

## grep

`grep` 用来查找文件里符合条件的字符串。 `grep` 会把符合条件的行显示出来。

```bash
[root@pooky init.d]# grep password /root/anaconda-ks.cfg
# Root password
[root@pooky init.d]# grep -i password /root/anaconda-ks.cfg # -i 忽略大小写
# Root password
[root@pooky ~]# grep pass.... /root/anaconda-ks.cfg  # 可以使用元字符 . 匹配任意一个字符
auth --enableshadow --passalgo=sha512
# Root password
[root@pooky ~]# grep pass....$ /root/anaconda-ks.cfg  # $ 表示结尾
auth --enableshadow --passalgo=sha512
# Root password
[root@pooky ~]# grep pass...d$ /root/anaconda-ks.cfg
# Root password
[root@pooky ~]# grep pass.*$ /root/anaconda-ks.cfg  # .* 就表示任意个字符
auth --enableshadow --passalgo=sha512
# Root password
user --groups=wheel --name=admin --passwd=$6$Lh0jvsS/YklFVYDM$WjPFI.WaMd3be/qiyFVUQkjEFN0PGQcnRTJFUDejJMUS24DA.M2rJ039hi/ubRiaNY4QNt661FARlxZqL.nCs0 --iscrypted --gecos="admin"
[root@pooky ~]# grep ^# /root/anaconda-ks.cfg    # 以 # 为开头的行
#version=DEVEL
# System authorization information
# Use CDROM installation media
# Use graphical install
```

### 常用参数

- `-n`：显示行号
- **`-C：num` `--context`：显示匹配行前后（Context） 各 num 行内容。最常用**。
- `-A num` `--after-context`：显示匹配行之后（After） 的 num 行内容。
- `-B num`	`--before-context`：显示匹配行之前（Before） 的 num 行内容。
- `-r` `--recursive`：递归搜索目录下的所有文件。
- **`-o`：只输出匹配到的部分（字符串），而不是输出包含匹配模式的整行**。
- `-E`：扩展正则表达式 让 `()`、`{}`、`|`、`+` 等元字符不再需要反斜杠转义。
- `-i`：忽略大小写。
- `-v`：**反向选择**，即过滤掉匹配指定模式的行，只**显示那些不匹配的行**。


### 应用场景

```bash
# 在日志中查找所有异常，并显示行号和前后 5 行上下文
grep -n -C 5 -i "exception\|error\|fail" /var/log/app/app.log

# 查找今天的错误 (结合日期过滤)
grep "$(date '+%Y-%m-%d')" /var/log/app.log | grep -i error

# 查找指定时间范围的日志
# -A 999999: 显示匹配行之后的 999999 行
# -B 999999: 显示匹配行之前的 999999 行
grep "2024-05-24 10:15:" app.log -A 999999 | grep "2024-05-24 10:20:" -B 999999
# 使用 sed（更可靠）
sed -n '/2024-05-24 10:15:/,/2024-05-24 10:20:/p' app.log
# 使用 awk
# 假如日志格式是 YYYY-MM-DD HH:MM:SS [日志内容]
# $1 是日期部分（如 2024-05-24），$2 是时间部分（如 10:15:23）
# $1" "$2 的意思是字符串连接，重新组成完整的时间字符串，然后进行字符串比较。
awk '$1" "$2 >= "2024-05-24 10:15:00" && $1" "$2 <= "2024-05-24 10:20:00"' app.log

# 统计404状态的请求
grep " 404 " /var/log/nginx/access.log | wc -l

# 找出访问量最大的IP (结合awk和sort)
# 
grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" access.log | sort | uniq -c | sort -nr | head -10

# 通过一个唯一的TraceID来追踪一个请求在整个集群中的流转
grep "abc123-trace-id" /var/log/microservice/*.log+
```

## uniq

`uniq` 是一个用于报告或忽略文件中的重复行的过滤器。它的一个关键前提是：**输入必须是排序过的，因为 `uniq` 只会检测相邻的重复行**。

- **`-c` `--count` 在每行前加上该行重复出现的次数。最常用参数，用于统计重复项的频率**。
- `-d` `--repeated` **仅显示重复出现的行**（每组重复行只显示一次）。快速找出有哪些内容是重复的。
- `-u` `--unique` **仅显示不曾重复出现的行**（独一无二的行）。找出只出现一次的条目，例如排查异常的单次访问。

### 应用场景

```bash
# 有一个用户列表 users.txt，想知道有哪些用户是重复的
sort users.txt | uniq -d

# 找出只出现一次的异常条目
grep "Failed password" /var/log/secure | sort | uniq -u
```

日志格式为 `[日期 时间] 错误信息`。需要统计有哪些类型的错误信息，而不关心它们发生的具体时间。

```bash
[2023-10-27 10:01:23] Connection timeout
[2023-10-27 10:05:45] Permission denied
[2023-10-27 10:07:12] Connection timeout
[2023-10-27 10:08:33] Disk full
```

```bash
# 先使用sed/awk处理掉`[`和`]`
sed 's/\[.*\] //' error.log | sort | uniq -c
```

## sort

对文本行进行排序，一般都是作为数据管道（pipe）的关键一环，与 `uniq`, `awk`, `head` 等命令组合，用于日志分析、数据统计和报告生成。

常用参数：

- `-n`：按数字大小进行排序，而不是字母顺序。
- `-r`、`--reverse`：逆序排序（降序）。
- `-k`：指定排序的键。
- `-t`、`--field-separator=SEP` 指定字段分隔符，默认是空格。处理 CSV 文件或以特定字符（如 `:, ,`）分隔的日志。
- `-u`、`--unique`：在排序的同时去除重复行。
- `-o`、`--output=FILE`：将结果输出到指定文件，可以覆盖原文件。
- **`-h`: 人类可读数字排序**，能正确比较 2K, 1M, 100G 的大小。

```bash
# 查看当前最消耗内存的10个进程
ps aux | sort -rnk 4 | head -10

# 按用户 ID（第三列）从小到大排序 /etc/passwd 文件。
sort -t ':' -nk 3 /etc/passwd
```


{{< callout type="info" >}}
**万能管道公式**：

`获取数据 (awk/grep/sed) -> 排序 (sort) -> 去重统计 (uniq -c) -> 再次排序 (sort -nr) -> 取顶部结果 (head)`
{{< /callout >}}


## sed

`sed` 命令一般用于对文本内容做替换：`sed [-hnV][-e <script>][-f <script 文件>] [文本文件]`，例如：`sed '/user1/s/user1/u1' /etc/passwd`。

常用参数：

- `-e`：指定一个或多个 `sed` 动作，多个动作之间用分号 `;` 隔开。
- `-f`：将 sed 的动作写在一个文件内，用 `–f filename` 执行 filename 内的 sed 动作
- **`-i[后缀]`：直接修改文件内容，这是运维中最常用也最危险的选项**。务必谨慎！
  - **`-i.bak`：编辑前先创建备份文件，原文件会被保存为 file.txt.bak。（强烈推荐的习惯）**
- `-n`：取消默认的完整输出，通常与 `p` 命令结合使用，只打印那些被修改或匹配的行。
- `-r`：不需要转义

### 替换

`sed 's/old/new/' filename`，将文件中所有的 `old` 替换为 `new`。

- `sed -e 's/old/new/' -e 's/old/new/' filename ...`，**可以执行多次替换脚本但是不能省略 `-e`**。
- `sed -i 's/old/nnew/' 's/old/new/' filename ...`，直接修改文件内容。
- `sed 's/foo/bar/g' file.txt` 将全文所有的 foo 替换为 bar。
  - `g`：全局替换，**不加 `g` 只替换每一行中第一个匹配到的** "foo"。
  - `p`：打印发生替换的那一行。与 `-n` 选项连用。
  - `i` 或 `I`：忽略大小写进行匹配。

### 删除

`sed /匹配模式/d` 删除匹配到的行：

- `sed '/^#/d' file.txt`，删除所有以 `#` 开头的行。
- `sed 's/^/# /' file.txt`，在每一行的行首添加 `#`，相当于注释掉所有行。

### 打印

`p` 打印命令，**打印匹配的行**。通常与 `-n` 选项一起使用。

- `sed -n '/error/p' /var/log/syslog`，只打印包含 `error` 的行，相当于 `grep "error"`。

### 追加

`a\text`：在指定行后追加文本。

`sed '/server_name www.example.com;/a\ return 301 https://$host$request_uri;' nginx.conf`，在 server_name 行后追加一条 301 重定向规则。

### 插入文本

`i\text`：在指定行前插入文本。

`sed '3i\# This is a new line' file.txt`，在第 3 行之前插入一行注释 。

### 替换整行

`c\text`：替换整行文本。

`sed '/old_line/c\This is the new line content' file.txt`

### 行范围

- `n`：第 n 行。`sed '5s/foo/bar/'` 只替换第 5 行的 foo。
- `n,m`：第 n 到 m 行。`sed '10,20s/foo/bar/g'`。
- `$`：最后一行。`sed '$s/foo/bar/'`。
- `/regexp/`：匹配正则表达式的行。`sed '/start/,/end/d'` 删除从包含 start 的行到包含 end 的行之间的所有内容。


### 应用场景

```bash
# 将旧 IP 地址替换为新 IP 地址，并创建备份文件
sed -i.bak 's/192.168.1.100/192.168.1.200/g' /etc/nginx/conf.d/*.conf

# 修改文件中的路径（注意：分隔符可以用其他字符，如 #，以避免和路径中的 / 冲突）
# 旧路径 /old/path 全局替换为新路径 /new/path
# `#` 作为分隔符，而不是常见的 `/`
sed -i 's#/old/path#/new/path#g' config.ini

# 删除配置文件中的所有空行和注释行（以 # 开头）
sed -i '/^#/d; /^$/d' /etc/foo.conf

# 或者写成多条 -e
sed -i -e '/^#/d' -e '/^$/d' /etc/foo.conf

# 只查看日志文件中特定时间范围内的行（例如 14:00 到 14:30）
sed -n '/May 10 14:00:00/,/May 10 14:30:00/p' /var/log/syslog

# 提取 Jenkins 构建日志中 Git 提交的哈希值（假设格式为 Commit: abc123def）
cat build.log | sed -n 's/.*Commit: \([a-f0-9]\{7,40\}\).*/\1/p'

# 提取本机的 IP 地址（假设是 eth0 网卡）
ip addr show eth0 | sed -n 's/.*inet \(192\.168[^/]*\).*/\1/p'

# 在脚本中动态修改配置文件中的端口号
NEW_PORT=8080
sed -i "s/^Port.*/Port $NEW_PORT/" /etc/ssh/sshd_config

# 直接删除文件 script.sh 中所有行尾的回车符（\r）
# \r 代表回车符（Carriage Return），是 Windows 换行符的一部分
# sed 会读取数据，直到遇到换行符 \n 为止，不是绝对的文件末尾
sed -i 's/\r$//' script.sh  # 这是一个非常常见的用法！

# 在每行的行首或行尾添加内容
sed -i 's/^/HEADER: /' logfile.txt  # 行首添加
sed -i 's/$/\\n/' file.txt          # 行尾添加换行符（实际是追加\n字符）
```

**使用扩展正则 `-r`：为了让命令更清晰易读，建议总是使用 `sed -r`，避免过多的反斜杠 `\`**。

## awk

awk 一般用于对文本内容进行统计，按需要的格式进行输出。一般是作为 sed 的一个补充。awk 可以看成是一种编程语言。

**特别擅长处理结构化文本数据（如日志、CSV、命令输出等）**。

awk 和 sed 的区别：

- awk 用于比较规范的文本处理，用于统计数量并输出指定字段。
- sed 一般用于把不规范的文本处理为规范的文本。

awk 的流程控制：

- **输入数据前例程 `BEGIN{}`**，读入数据前执行，做一些预处理操作。
- **主输入循环 `{}`**，处理读取的每一行。
- **所有文件读取完成例程 `END{}`**，读取操作完成后执行，做一些数据汇总。

常用的写法是只写主输入循环。

记录和字段：

- 每一行叫做 awk 的记录。
- 使用空格、制表符分隔开的单词叫做字段。
- 可以指定分隔的字段。

字段的引用：

- **`$1` `$2` ... `$n` 表示每一个字段，`$0` 表示当前行**，`awk '{print $1, $2, $3} filename'`
- **$NF 是最后一个字段，和 `NF` 不一样**。
- **`-F` 改变字段的分隔符**，`awk -F ',' '{print $1, $2, $3}' filename`，分隔符可以使用正则表达式。

系统变量：

- **`NR` 表示当前处理的是第几行**。
- **`NF` 字段数量**，所以最后一个字段内容可以用 `$NF` 取出，**`$(NF-1)` 代表倒数第二个字段**。
- **`FS` 字段分隔符**，默认是空格和制表符。
- `RS` 行分隔符，用于分割每一行，默认是换行符。
- `OFS` 输出的字段分隔符，用于打印时分隔字段，默认为空格。
- **`ORS` 输出行分隔符**，用于打印时分隔记录，默认为换行符。
- **`FNR` 行数**。

常用参数：

- `-F`：指定输入字段分隔符。这是最常用的参数。
  - `awk -F: '{print $1}' /etc/passwd` // 使用冒号 : 作为分隔符。
  - `awk -F'[ :]' '{print $2}' file` // 使用空格或冒号作为分隔符（正则表达式）。
- `-v`：定义变量，用于从 Shell 向 awk 脚本传递值。`awk -v name="Alice" '{print name, $1}' file.txt`。
- `-f`：从脚本文件中读取 awk 命令，用于复杂的脚本。`awk -f script.awk data.txt`。

### 应用场景

```bash
# 提取 ps 命令输出的进程 ID 和命令 (PID 和 CMD)
ps aux | awk '{print $2, $11}' | head

# 获取所有登录的用户名
who | awk '{print $1}'

# 分析 /etc/passwd，提取用户名和使用的 shell
awk -F: '{print $1, $7}' /etc/passwd

# 分析 /etc/passwd，提取用户名和使用的 shell
awk -F: '{print $1, $7}' /etc/passwd

# 正则过滤
awk -F "'" '/^menu/{ print $1 }' /boot/grub2/grub.cfg
menuentry
menuentry
menuentry

# 条件过滤
# 显示磁盘使用率超过 80% 的分区
df -h | awk '$5+0 > 80 {print $1, $5}'

# 找出内存使用超过 100MB 的进程
ps aux | awk '$6 > 100000 {print $11, $6/1024 "MB"}'

# 打印第 5 到第 10 行
awk 'NR>=5 && NR<=10' /var/log/syslog

# 计算文件总大小（第5列是大小）
ls -l | awk '{sum += $5} END {print "Total Size: ", sum, "bytes"}'

# 统计日志中每种 HTTP 状态码的出现次数（假设第9列是状态码）
awk '{status_count[$9]++} END {for(s in status_count) print s, status_count[s]}' access.log

# 计算系统平均负载（最后15分钟是$3）
uptime | awk '{print "15-min load average: ", $NF}' # NF 是最后一个字段


# 格式化输出 /etc/passwd
awk -F: 'BEGIN {printf "%-15s %-10s\n", "Username", "Shell"} {printf "%-15s %-10s\n", $1, $7}' /etc/passwd | head

# 为输出添加表头
netstat -tnlp | awk 'BEGIN {print "Proto Recv-Q Send-Q Local Address"} NR>2 {print $1, $2, $3, $4}'

# 假设 Nginx 访问日志格式为
# 192.168.1.1 - - [10/May/2023:14:12:33 +0800] "GET /index.html HTTP/1.1" 200 1234
# 统计每个 IP 的访问次数
awk '{ip_count[$1]++} END {for(ip in ip_count) print ip, ip_count[ip]}' access.log | sort -nr -k2

# 统计最受欢迎的 URL（第7列）
awk '{url_count[$7]++} END {for(url in url_count) print url_count[url], url}' access.log | sort -nr | head
```

#### 表达式

赋值操作符：

- `=`，`var1 = "name"`，`var2 = $1`
- `++` `--` `+=` `-=` `*=` `/+` `%=` `^=`

算数操作符：

- `+` `-` `*` `/` `%` `^`

系统变量：

- `FS` 字段分隔符，默认是空格和制表符。
- `RS` 行分隔符，用于分割每一行，默认是换行符。
- `OFS` 输出的字段分隔符，用于打印时分隔字段，默认为空格。
- `ORS` 输出行分隔符，用于打印时分隔记录，默认为换行符。
- `NR` 表示当前处理的是第几行。
- `FNR` 行数。
- `NF` 字段数量，所以最后一个字段内容可以用 `$NF` 取出，`$(NF-1)` 代表倒数第二个字段。

```bash
[root@SGDLITVM0905 ~]# head -5 /etc/passwd | awk 'BEGIN{FS=":"}{print $1}'   # BEGIN{FS=":"} 表示在读入之前设置字段分隔符为 :，也可以写成 awk -F ":" '{print $1}'
root
bin
daemon
adm
lp
[root@SGDLITVM0905 ~]# head -5 /etc/passwd | awk 'BEGIN{FS=":"}{print $1,$2}'
root x          # 可以看出输出的字段分隔符默认为空格
bin x
daemon x
adm x
lp x
[root@SGDLITVM0905 ~]# head -5 /etc/passwd | awk 'BEGIN{FS=":";OFS="-"}{print $1,$2}'   # 输出的字段分隔符设置为 -
root-x
bin-x
daemon-x
adm-x
lp-x
[root@SGDLITVM0905 ~]# head -5 /etc/passwd | awk 'BEGIN{RS=":"}{print $0}'   # 已 : 为行分隔符，输出每一行
root
x
0
0
root
/root
/bin/bash
bin
x
1
1
bin
/bin
/sbin/nologin
daemon
[root@SGDLITVM0905 ~]# head -5 /etc/passwd | awk '{print NR}'   # 显示行号
1
2
3
4
5
[root@SGDLITVM0905 ~]# head -5 /etc/passwd | awk '{print NR, $0}'
1 root:x:0:0:root:/root:/bin/bash
2 bin:x:1:1:bin:/bin:/sbin/nologin
3 daemon:x:2:2:daemon:/sbin:/sbin/nologin
4 adm:x:3:4:adm:/var/adm:/sbin/nologin
5 lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
[root@SGDLITVM0905 ~]# awk '{print FNR, $0}' /etc/hosts /etc/hosts    # FNR 会重排行号
1 127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
2 #::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
3
4 16.187.191.150 SGDLITVM0905.hpeswlab.net SGDLITVM0905
1 127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
2 #::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
3
4 16.187.191.150 SGDLITVM0905.hpeswlab.net SGDLITVM0905
You have new mail in /var/spool/mail/root
[root@SGDLITVM0905 ~]# awk '{print NR, $0}' /etc/hosts /etc/hosts   # FNR 不会重排行号
1 127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
2 #::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
3
4 16.187.191.150 SGDLITVM0905.hpeswlab.net SGDLITVM0905
5 127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
6 #::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
7
8 16.187.191.150 SGDLITVM0905.hpeswlab.net SGDLITVM0905
[root@SGDLITVM0905 ~]# head -5 /etc/passwd | awk 'BEGIN{FS=":"}{print NF}'  # NF 输出字段数量
7
7
7
7
7
You have new mail in /var/spool/mail/root
[root@SGDLITVM0905 ~]# head -5 /etc/passwd | awk 'BEGIN{FS=":"}{print $NF}' # $NF 就可以获取到最后一个字段的内容
/bin/bash
/sbin/nologin
/sbin/nologin
/sbin/nologin
/sbin/nologin

```

关系操作符：

- `<` `>` `<=` `>=` `==` `!=` `~` `!~`

布尔操作符：

- `&&` `||` `!`

条件语句：

```bash
if (表达式)
  awk 语句1
[ else
  awk 语句2
]  
```

多个语句可以使用 `{}` 括起来。

```bash
[root@SGDLITVM0905 ~]# cat score.txt
user1 60 61 62 63 64 65
user2 70 71 72 73 74 75
user3 80 81 82 83 84 85
user4 90 91 92 93 94 95
[root@SGDLITVM0905 ~]# awk '{if($2>=80) print $1}' score.txt
user3
user4
[root@SGDLITVM0905 ~]# awk '{if($2>=80) print $1; print $2}' score.txt # 这种写法会把所有的第二个字段输出
60
70
user3
80
user4
90
[root@SGDLITVM0905 ~]# awk '{if($2>=80) {print $1; print $2} }' score.txt # 如果想一起输出要加上 {} ，多个语句一起执行
60
70
user3
80
user4
90
```

`while` 循环：

```bash
while(表达式)
  awk 语句1
```

`do` 循环：

```bash
do {
  awk 语句1
}while(表达式)
```

`for` 循环：

```bash
for(初始值;判断条件;累加)
  awk 语句1
```

可以使用 `break` 和 `continue`。

```bash
[root@SGDLITVM0905 ~]# cat score.txt
user1 60 61 62 63 64 65
user2 70 71 72 73 74 75
user3 80 81 82 83 84 85
user4 90 91 92 93 94 95
[root@SGDLITVM0905 ~]# head -1 score.txt
user1 60 61 62 63 64 65
[root@SGDLITVM0905 ~]# head -1 score.txt | awk 'for(c=2;c<=NF;c++) print c'
2
3
4
5
6
7
[root@SGDLITVM0905 ~]# head -1 score.txt | awk 'for(c=2;c<=NF;c++) print $c' # 输出值
61
62
63
64
65
[root@SGDLITVM0905 ~]# head -1 score.txt | awk 'for(c=2;c<=NF;c++) print $c' # 输出值
61
62
63
64
65
```

数组：

- `数组[下标] = 值`，初始化数组。下标可以是数字，也可以是字符串。
- `for (变量 in 数组)`，`数组[变量]` 获取数组元素
- `delete 数组[下标]` 删除数组元素

```bash
[root@SGDLITVM0905 ~]# cat score.txt
user1 60 61 62 63 64 65
user2 70 71 72 73 74 75
user3 80 81 82 83 84 85
user4 90 91 92 93 94 95
[root@SGDLITVM0905 ~]# awk '{ sum=0; for(column=2;column<=NF;column++) sum+=$column; print sum }' score.txt # 计算每个人的总分
375
435
495
555
[root@SGDLITVM0905 ~]# [root@SGDLITVM0905 ~]# awk '{ sum=0; for(column=2;column<=NF;column++) sum+=$column; avg[$1]=sum/(NF-1); }END{ for( user in avg) print user, avg[user]}' score.txt  # 计算每个人的平均分 并在 END 例程中格式化输出
user1 62.5
user2 72.5
user3 82.5
user4 92.5

```

awk 脚本可以保存到文件：

```bash
[root@SGDLITVM0905 ~]# awk -f avg.awk score.txt
user1 62.5
user2 72.5
user3 82.5
user4 92.5

```

- `-f` 加载 awk 文件。
- `avg.awk` 文件的内容：`{ sum=0; for(column=2;column<=NF;column++) sum+=$column; avg[$1]=sum/(NF-1); }END{ for( user in avg) print user, avg[user]}`。

命令行参数数组：

- `ARGC` 命令行参数数组的长度。
- `ARGV` 命令行参数数组。

```bash
[root@SGDLITVM0905 ~]# cat arg.awk
BEGIN{
  for(x=0;x<ARGC;x++)
    print ARGV[x]
  print ARGC
}
[root@SGDLITVM0905 ~]# awk -f arg.awk
awk
1
[root@SGDLITVM0905 ~]# awk -f arg.awk 11 22 33
awk
11
22
33
4
```

`ARGV[0]` 就是命令本身。

```bash
[root@SGDLITVM0905 ~]# cat avg.awk
{
  sum = 0
  for ( c = 2; c <= NF; c++ )
    sum += $c

  avg[$1] = sum / ( NF-1 )
  print $1, avg[$1]
  
}
END{
  for ( usr in avg)
    sum_all += avg[user]

  avg_all = sum_all / NR
  
  for ( user in avg )
    if ( avg[user] > avg_all )
      above++
    else
      below++

  print "above", above
  print "below", below
  
}
[root@SGDLITVM0905 ~]# awk -f avg.awk score.txt
user1 62.5
user2 72.5
user3 82.5
user4 92.5
above 4
below 1
```

awk 函数：

- 算数函数
  - `sin()` `cos()` `int()` `rand()` `srand()`
- 字符串函数
  - `toupper(s)` `tolower(s)` `length(s)` `split(s,a,sep)` `match(s,r)` `substr(s,p,n)`
- 自定义函数，自定义函数一定要写在 `BEGIN` 主循环 `END` 例程的外面：
  ```bash
  function 函数名 ( 参数 ) {
    awk 语句
    return awk 变量
  }
  ```

示例：

```bash
[root@SGDLITVM0905 ~]# awk 'BEGIN{pi=3.14; print int(pi)}'
3
[root@SGDLITVM0905 ~]# awk 'BEGIN{print rand()}'   # 这是一个伪随机数
0.237788
[root@SGDLITVM0905 ~]# awk 'BEGIN{print rand()}'
0.237788
[root@SGDLITVM0905 ~]# awk 'BEGIN{print rand()}'
0.237788
[root@SGDLITVM0905 ~]# awk 'BEGIN{srand();print rand()}'   # srand 会重新获取种子。范围是 0 ~ 1
0.960391
[root@SGDLITVM0905 ~]# awk 'BEGIN{srand();print rand()}'
0.0422737
[root@SGDLITVM0905 ~]# awk 'BEGIN{srand();print rand()}'
0.555768
[root@SGDLITVM0905 ~]# awk 'function a() { return 0 } BEGIN{ print a()}'
0
[root@SGDLITVM0905 ~]# awk 'function double(str) { return str str } BEGIN{ print double("hello")}'
hellohello

```
