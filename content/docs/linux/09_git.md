---
title: Git
weight: 9
---

## git

[Git 命令的一些使用技巧](https://shipengqi.github.io/posts/2020-01-31-git-usage/)。

## gh

gh 是 GitHub CLI（命令行工具），可以直接在命令行中执行常见的 GitHub 操作（如创建仓库、PR、Issue、Review、Actions 等），非常适合 DevOps 或日常运维自动化使用。


### 安装与认证

```bash
# 安装（macOS）
brew install gh

# 登录 GitHub（支持 Web 登录或 Token）
gh auth login

# 查看当前登录信息
gh auth status

# 退出登录
gh auth logout
```

### 仓库管理

```bash
# 创建一个新仓库（本地 + 远程）
gh repo create my-repo --public

# 只在 GitHub 上创建仓库
gh repo create my-repo --public --confirm --source=.

# 克隆仓库（替代 git clone）
gh repo clone user/repo

# 打开当前仓库的 GitHub 页面
gh repo view --web

# 查看仓库信息
gh repo view user/repo

# Fork 仓库
gh repo fork user/repo

# 删除远程仓库
gh repo delete user/repo
```

### Pull Request 管理

```bash
# 创建 PR（当前分支 -> main）
gh pr create --base main --title "Fix bug" --body "Bug details..."

# 查看 PR 列表
gh pr list

# 查看单个 PR 详情
gh pr view 123
gh pr view 123 --web     # 打开网页查看

# 合并 PR
gh pr merge 123          # 默认创建 merge commit
gh pr merge 123 --squash # squash 合并
gh pr merge 123 --rebase # rebase 合并

# 检出某个 PR（拉取分支进行测试）
gh pr checkout 123

# 关闭 PR
gh pr close 123
```

### Issue 管理

```bash
# 创建 Issue
gh issue create --title "API bug" --body "Detail about bug"

# 查看 Issue 列表
gh issue list

# 查看 Issue 详情
gh issue view 42
gh issue view 42 --web

# 关闭 Issue
gh issue close 42

# 重新打开 Issue
gh issue reopen 42
```

Actions：

```bash
# 查看最近的 workflow 运行
gh run list

# 查看运行详情
gh run view 123456789

# 打开 workflow 运行网页
gh run view 123456789 --web

# 重新运行 workflow
gh run rerun 123456789

# 取消运行
gh run cancel 123456789

# 下载 workflow 日志
gh run download 123456789
```

### Release 与 Tag 管理

```bash
# 创建 release
gh release create v1.0.0 --title "v1.0.0" --notes "Initial release"

# 附加文件
gh release create v1.0.0 ./build/app.tar.gz

# 查看 release 列表
gh release list

# 查看 release 详情
gh release view v1.0.0

# 删除 release
gh release delete v1.0.0
```

### 常见运维场景

自动重跑失败的 Actions：

```bash
gh run list --limit 10 --json databaseId,status | jq -r '.[] | select(.status=="failure") | .databaseId' | xargs -n1 gh run rerun
```

快速打开 PR 或 Issue：

```bash
gh pr view --web
gh issue view 101 --web
```