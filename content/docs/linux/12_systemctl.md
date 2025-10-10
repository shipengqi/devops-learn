---
title: Systemd
weight: 12
---

Systemd 管理的对象称为 Unit，每个 Unit 都有一个对应的配置文件。

- `.service`：服务（最常用），如 nginx, mysql, docker。
- `.socket`：套接字。
- `.mount`：挂载点。
- `.timer`：定时任务（替代 cron）。

命令：

- `systemctl start <服务名>`：启动一个服务，部署新应用后启动服务。
- `systemctl stop <服务名>`：停止一个服务，需要紧急停止服务时。
- `systemctl restart <服务名>`：重启一个服务，修改配置文件后，使配置生效。
- `systemctl reload <服务名>`：重载一个服务，让服务重新加载配置而不中断当前连接（如 nginx）。
- `systemctl reload-or-restart <服务名>`：能重启，如果服务支持 `reload` 则 `reload`，否则 `restart`。
- `systemctl status <服务名>`：查看服务的详细状态（最常用），故障排查第一步。查看服务是否活跃、是否有错误日志、进程 ID 等。
- `systemctl is-active <服务名>`：检查服务是否正在运行，在脚本中判断服务状态，返回 `active` 或 `inactive`。
- `systemctl is-enabled <服务名>`：检查服务是否开机自启，在脚本中判断服务启动模式，返回 enabled 或 disabled，
- `systemctl is-failed <服务名>`：检查服务是否启动失败，检查服务是否处于故障状态，返回 failed 或 active。
- `systemctl enable <服务名>`：启用开机自动启动，安装新服务后，必须设置以保证服务器重启后服务能自动运行。
- `systemctl disable <服务名>`：禁用开机自动启动。
- `systemctl mask <服务名>`：屏蔽服务（无法手动或自动启动）彻底禁用一个服务，防止被意外启动（**比 disable 更彻底**）。
- `systemctl unmask <服务名>`：取消屏蔽服务。
- `systemctl daemon-reload`：重载 Systemd 配置，修改了服务的配置文件（`.service` 文件）后，必须执行此命令，
让 Systemd 识别新的配置。**注意：这与 `reload` 服务不同**。
- `systemctl list-units --type=service`：列出所有已加载的服务及其状态。
- `systemctl list-unit-files --type=service`：列出所有服务的开机启动状态。
- `systemctl cat <服务名>`：显示服务的配置文件内容，快速查看服务的配置，而不用去找文件位置。
- `systemctl edit <服务名>`：编辑服务配置（会创建覆盖片段），修改服务配置的推荐方式，避免直接修改主配置文件，
- `systemctl reboot`：重启系统，安全的系统重启方式。
- `systemctl poweroff`：关闭系统，安全的系统关机方式。

查看服务状态：

```bash
pooky@DESKTOP-DMAGDPE:~$ systemctl status cron
● cron.service - Regular background program processing daemon
     Loaded: loaded (/usr/lib/systemd/system/cron.service; enabled; preset: enabled)
     Active: active (running) since Fri 2025-08-22 11:01:51 CST; 1 day 5h ago
       Docs: man:cron(8)
   Main PID: 164 (cron)
      Tasks: 1 (limit: 16586)
     Memory: 1.2M (peak: 4.9M)
        CPU: 2.054s
     CGroup: /system.slice/cron.service
             └─164 /usr/sbin/cron -f -P
```

- `Loaded`：单元配置文件位置，以及是否开机启动（enabled）。
- `Active`：当前状态，如 active (running)（运行中）、inactive (dead)（未运行）、failed（失败）。
- `Main PID`：主进程ID。
- `CGroup`：CGroup 信息，包含相关进程。
- 日志片段：最后几条相关日志，对排查故障极其重要。