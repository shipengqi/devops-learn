---
title: 目录结构
weight: 2
---

如果 `.tfvars` 文件包含敏感数据，例如密码、访问密钥等，建议将其添加到 `.gitignore` 文件中，避免将敏感数据提交到 Git 仓库中。

`.terraform.lock.hcl` 包含了版本信息，应该提交到仓库里。
