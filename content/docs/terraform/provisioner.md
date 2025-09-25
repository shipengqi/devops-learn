---
title: Provisioner
weight: 4
---

某些基础设施对象需要在创建后执行特定的操作才能正式工作。

像这样创建后执行的操作可以使用**预置器**(Provisioner)。预置器是由 Terraform 所提供的另一组插件，每种预置器可以在资源对象创建后执行不同类型的操作。

## cloud-init

不少公有云厂商的虚拟机都提供了 cloud-init 功能，可以让我们在虚拟机实例第一次启动时执行一段自定义的脚本来执行一些初始化操作。

首先要指出的是，provisioner 的官方文档里明确指出，由于预置器内部的行为 Terraform 无法感知，无法将它执行的变更纳入到声明式的代码管理中，所以预置器应被作为最后的手段使用，那么也就是说，如果 cloud-init 能够满足我们的要求，那么我们应该优先使用 cloud-init。


## user_data

`user_data` 执行的命令, Terraform 无法感知. 如果命令失败,不得不访问服务器,再进行调试.

## user_data 和 provisioner 区别

`user_data`: 原理是在实例启动时,将 `user_data` 中的内容写入到实例的 `/var/lib/cloud/instance/user-data.txt` 文件中,并执行该文件中的内容.

`provisioner`: 原理是在实例启动后, Terraform 通过 SSH 连接到实例,并执行 `provisioner` 中的命令.

### 为什么不建议使用 provisioner



