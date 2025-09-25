---
title: Terraform
weight: 1
---

## 概念

1. Providers (提供商)
   - 是什么：Provider 是 Terraform 的插件，用于与特定的云平台（如 AWS, Azure, GCP）、 SaaS 服务（如 Cloudflare, Datadog）或本地基础设施（如 vSphere, Docker）进行交互。
   - 作用：Provider 负责理解 API 交互并将资源创建、更新和删除的请求翻译成具体的 API 调用。
   - 如何使用：在配置中通过 provider 块进行声明和配置（例如，设置 region 和 access key）。
   - 示例：aws, azurerm, google, kubernetes, null。
2. Resources (资源)
   - 是什么：Resource 是 Terraform 配置中最重要的元素，代表一个具体的基础设施资源。
   - 作用：定义一个需要被创建、管理和销毁的资源实体，例如一台虚拟机、一个网络安全组、一个 S3 存储桶。
   - 结构：`resource "resource_type" "resource_name" { ... }`
     - `resource_type`：由 Provider 提供（如 `aws_instance`）。
     - `resource_name`：你在当前 Terraform 模块内给这个资源起的逻辑名称（标识符）。
   - 示例：`resource "aws_instance" "my_web_server" { ami = "ami-12345", instance_type = "t2.micro" }`
3. Input Variables (输入变量)
   - 是什么：类似于函数的参数，用于**从外部向 Terraform 模块传递值**。
   - 作用：参数化配置，提高代码的灵活性和可复用性。避免将敏感信息或环境特定的值硬编码在配置文件中。
   - 如何定义：在 `variables.tf` 文件中使用 variable 块声明。
   - 如何赋值：可以通过命令行 `-var "var_name=var_value"` 选项、`.tfvars` 文件、环境变量等方式传入。
4. Output Values (输出值)
   - 是什么：类似于函数的返回值，用于**将模块内部资源的信息暴露给外部**。
   - 作用：共享资源的属性（例如，新创建服务器的公有 IP 地址），以便其他 Terraform 配置或外部世界可以使用。
   - 如何定义：在 `outputs.tf` 文件中使用 output 块声明。
5. State (状态)
   - 是什么：一个名为 `terraform.tfstate` 的 JSON 文件，它极其重要。它**存储了 Terraform 所管理基础设施的当前状态和属性映射**。
   - 作用：
     - 映射现实：将你的配置文件（`.tf`）中的资源定义映射到现实世界中的真实资源 ID。
     - 元数据存储：**存储资源的依赖关系、属性等信息，用于计算增量变更**。
     - 性能：缓存资源信息，避免每次执行都需查询所有云资源。
   - 重要提示：**必须安全地存储和备份状态文件（例如使用远程后端如 S3 + DynamoDB），严禁手动修改。团队成员间应共享同一份状态文件以避免配置冲突**。
6. Modules (模块)
   - 是什么：**将多个资源组合成一个更大、可重用单元的容器**。一个模块就是一个包含 Terraform 配置文件（`main.tf`, `variables.tf`, `outputs.tf`）的目录。
   - 作用：**抽象和封装基础设施，实现代码复用和组织化**。你可以创建自己的模块，**也可以使用来自 Terraform Registry 的公共模块**。
   - **根模块**：执行 `terraform apply` 时所在的目录。
   - **子模块**：在配置中通过 `module` 块调用的其他模块。
7. Data Sources (数据源)
   - 是什么：数据源允许 Terraform 从外部数据源获取信息，而不是从本地配置文件中获取。比如现在要在一个现有的 aws VPC 中创建一个子网，而不是新的 VPC，如何获取 VPC id。**Resource 用于创建和管理基础设施资源，Data Source 用于检索和利用现有基础设施资源的信息**。
     - 可以从控制台获取 VPC id，比较麻烦。
     - 可以从数据源中获取 VPC id。
   - 作用：**检索和利用现有基础设施资源的信息，在配置中引用**。
   - 如何定义：在 `data.tf` 文件中使用 `data` 块声明。
   - 示例：`data "aws_ami" "example" { most_recent = true, owners = ["self"] }`


Resource 与 Data Source 可以看作为函数，**Resource 的定义是一个创建资源的函数，然后传递参数给 Terraform，来创建对应的实体**。**Data Source 可以看作是一个查找并返回现有实体信息的函数，可以指定查询的条件和参数**。

## 基本工作流程

1. Init 初始化，初始化工作目录。下载配置中声明的 Provider 插件、模块等依赖项。
   - `terraform init`，**第一次使用新配置时，或添加/修改了 Provider 或模块后**。
2. Plan 计划，它会对比状态文件（当前状态）和配置文件（期望状态），然后生成一个执行计划，算出来需要执行的步骤。
   - `terraform plan` 在真正应用变更之前进行审查和确认，避免意外操作。
3. Apply 应用，会根据执行计划，来执行你的操作。
   - `terraform apply`，执行计划中的变更，使现实基础设施的状态与你的配置保持一致。
   - 你可以在 `apply` 时添加 `-auto-approve` 参数，来自动 approve 这个计划。否则会提示你是否 approve 这个计划。
   - 你也可以在 `apply` 时添加 `-target` 参数，来指定只执行某个资源。
   - 你也可以在 `apply` 时添加 `-destroy` 参数，来指定只删除某个资源。
4. Destroy 销毁，会销毁所有资源。也需要确认是否销毁。支持 `-auto-approve`。
   - `terraform destroy`，清理环境，避免产生不必要的费用。
   - 删除资源可以直接在配置文件中删除配置，然后执行 `terraform apply` 来删除资源（推荐）。
   - 也可以使用 `terraform destroy -target <资源类型>.<资源名称>` 来删除指定资源，不推荐，因为会导致状态与配置文件不一致。**所有的更改都应该通过配置文件来进行**。

## 语法

### 参数

HCL 中的参数就是将一个值赋给一个特定的名称：

```hcl
name = "example"
```

等号前的标识符就是参数名，等号后的表达式就是参数值。

### 标识符

- 合法的标识符可以包含字母、数字、下划线(`_`)以及连字符(`-`)。
- **标识符首字母不可以为数字**。

### 注释

```hcl
  # Configuration options 单行注释
  // Configuration options 单行注释
  /* 多行注释
  Configuration options
  Configuration options
  */
```

### 核心配置块

- `terraform` 配置块：定义 Terraform 版本、插件源等。
  - `required_providers`：指定所需的 Provider 插件源及其版本。
  - `backend`：**配置状态文件的存储后端**，如本地文件、远程后端（如 S3 + DynamoDB）等。
- `provider` 配置块
  - **定义使用的 Provider 插件**，如 AWS、Azure、GCP 等。
  - **配置 Provider 插件的认证信息**，如 API 密钥、访问令牌等。
- `resource` 配置块
  - **定义要创建的资源**，如 AWS 实例、GCP 存储桶等。
  - **配置资源的属性**，如实例类型、存储桶名称等。
- `variable` 配置块
  - **定义输入变量**，如输入参数、环境变量等。
  - **配置变量的默认值**，如 `default = "us-east-1"`。
- `output` 配置块
  - **定义输出值**，应用完成后公开一些有用的信息（如服务器的 IP 地址）。
  - **配置输出值的描述**，如 `description = "The ID of the created instance"`。
  - **配置输出值的敏感信息**，如 `sensitive = true`，可以防止输出值被打印到日志中。
- `data` 配置块
  - **定义数据源**，用于从提供商获取外部数据或查询已有资源的信息，以便在配置中使用。
  - **配置数据源的属性**，如实例 ID、存储桶名称等。
- `module` 配置块
  - **调用模块**，将多个资源封装成一个可重用的单元。
  - **配置模块的参数**，对于 module 来说,输入变量就像函数的参数,输出值就像函数的返回值. output 用来导出资源的属性到父级模块
  - 只有将一组资源组合在一起的 module 才有意义, 例如一组网络资源, 一组数据库资源等.
  - 可以创建自己的模块,也可以使用其他存在的模块,例如 terraform 官方提供的模块 terraform-aws-modules/vpc
- `locals` 配置块
  - **定义本地变量**，用于在配置中重复使用的值。
  - **配置本地变量的表达式**，如 `local_var = "value"`。

## 失败

`apply` 失败会生成 crash.log 文件, 可以根据这个文件来调试.

## 使用已经存在的 module

```hcl
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}
```



## 配置文件

1. Provider 部分

表示 provider 部分，用来指定你要使用的 provider，比如 aws，azure，gcp 等。

```hcl
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.10.0"
    }
  }
}

provider "aws" {
  # Configuration options
}
```


对于多个 provider 的情况，可以单独抽出一个 `providers.tf` 文件。

```hcl
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.10.0"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.41.0"
    }
    tencentcloud = {
      source = "tencentcloudstack/tencentcloud"
      version = "1.123.0"
    }

  }
}
```


2. Resource 部分

表示 resource 部分，用来指定你要创建的资源，比如 aws 中的 ec2，rds 等。

```hcl
# resource 
# "aws_instance" 表示资源类型
# "example" 表示资源名称，注意这个名字是你自己定义的，是 local 的，不是 aws 中的资源名称。
resource "aws_instance" "example" {
  name = "example" # aws 中的资源名称
  ami = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}
```

3. Variable 文件

例如定义 resource 我们需要填一些参数，比如 ami，instance type 等。这些参数我们可以定义在 variable 文件中。在 variable 文件中定义的变量的值，然后在 resource 中引用，避免在 `main.tf` 中改来改去。


4. Output 文件

在有些情况在，只有当这个资源被创建出来之后，你才知道这个资源的一些信息，比如 id， ip 地址，dns 名称等。

如果你想使用这些值，作为以下资源的输入参数，就可以使用 output 来导出。

## 示例

### 简单示例

`main.tf`：

```hcl
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.41.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  # features 是必须的，可以为空
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "ExampleRG"
  location = "West Europe"
}
```

运行 `terraform init` 初始化。会去搜索对应版本的 provider 插件下载，并安装到 `.terraform` 目录下。这个目录下会有一个可执行文件，就是 provider。

`.terraform.lock.hcl` 是用来记录 provider 插件的版本信息的。包括 hash 值。

如果已经运行了 az 登录，那么执行 `terraform plan`：

```bash
terraform plan

# 输出
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # azurerm_resource_group.example will be created
  + resource "azurerm_resource_group" "example" {
      + id       = (known after apply)
      + location = "West Europe"
      + name     = "ExampleRG"
    }

Plan: 1 to add, 0 to change, 0 to destroy.

```

执行 `terraform apply` 来创建资源。

输出：

```bash
Terraform will perform the following actions:

  # azurerm_resource_group.example will be created
  + resource "azurerm_resource_group" "example" {
      + id       = (known after apply)
      + location = "West Europe"
      + name     = "ExampleRG"
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

执行完以后会同时创建一个 `terraform.tfstate` 文件，用来记录所有被 terraform 管理的资源的状态。

terraform 会使用这个状态文件去和 `main.tf` 中定义的资源进行对比，来判断是否需要创建、更新、删除资源。来达到预期的状态。

### Variable 示例

`variables.tf`：

```hcl
variable "location" {
  type = string
  default = "West Europe"
  description = "The location of the resource group."
}

variable "storage_account_name" {
  type = string
  description = "The name of the storage account."
  # 没有默认值，因为每个 storage account 名称在 azure 中是全局唯一的。
}
```

`main.tf`：

```hcl

# locals 也是一个变量，本地变量
# 本地变量可存储重复出现的值或表达式，例如多次引用的配置信息。通过 locals 块声明后，可避免在多个地方重复编写相同内容
# locals 的作用域是模块级别的
#   - 目录作用域：在同一个 Terraform 模块目录（包含所有 .tf 文件的那个目录）中，任何地方定义的 locals 块在整个模块中都可用
#   - 全局可见：一旦在某个 locals 块中定义了一个值（例如 local.name_prefix），你可以在同一个模块的任何 .tf 文件中通过 local.name_prefix 引用它
#   - 不可跨模块：locals 对于父模块或子模块是不可见的。如果需要在模块间共享值，应该使用 output。
# 引用 locals 变量时，直接使用 local.<变量名>
locals {
  tags = {
    usage = "test"
    owner = "sid"
  }
}


resource "azurerm_resource_group" "resourcegroup" {
  # name     = "${var.prefix}-RG" 这是另一种变量的用法，可以将 var.prefix 和 -RG 组成一个字符串
  name     = "ExampleRG"
  location = var.location # 引用变量，使用 var.<变量名>
}

resource "azurerm_storage_account" "storageaccount" {
  name = var.storage_account_name
  resource_group_name = azurerm_resource_group.resourcegroup.name # 引用资源，使用 <资源类型>.<资源名称>.<key>
  location = azurerm_resource_group.resourcegroup.location        # 这种方式表示在 resourcegroup 创建完了以后使用 resourcegroup 的 name/location

  account_tier = "Standard"
  account_replication_type = "LRS"
  tags = local.tags
}
```

`storage_account_name` 没有默认值，所以肯定需要指定一个值。有两种方式：

1. 在 `terraform apply` 时，会提示输入 `storage_account_name` 的值。
2. 在 `terraform plan/apply` 时，需要添加 `-var "storage_account_name=mystorageaccount"` 来指定这个值。不方便。
3. 创建 **`terraform.tfvars` 文件**，在文件中指定变量的值。最推荐的方式。
4. 环境变量

`terraform.tfvars` 文件：

```hcl
storage_account_name = "mystorageaccount"
```


#### 环境变量

可以通过设置名为 **`TF_VAR_<NAME> `的环境变量为输入变量赋值**，例如：

```bash
$ export TF_VAR_image_id=ami-abc123
$ terraform plan
```

Terraform 要求环境变量中的 `<NAME>` 与 Terraform 代码中定义的输入变量名大小写完全一致。

```hcl
variable "image_id" {
  type = string
}
```


环境变量传值非常适合在自动化流水线中使用，尤其适合用来传递敏感数据，类似密码、访问密钥等。

#### 多个环境

对于多个环境，每个环境的变量值可能会不同。

例如：

- 开发环境
- 测试环境
- 生产环境

每个环境的变量值可能会不同，每个环境都创建一个 `terraform.tfvars` 文件。例如：

- 开发环境：`terraform-dev.tfvars`
- 测试环境：`terraform-test.tfvars`
- 生产环境：`terraform-prod.tfvars`

`apply` 时，需要添加 `-var-file` 来指定 `terraform.tfvars` 文件的路径。例如：

```bash
terraform apply -var-file=terraform.dev.tfvars
```

#### Variable 类型

- string
- number
- bool
- `list(<TYPE>)`：列表，例如 `list(string)`
- `set(<TYPE>)`：集合，例如 `set(string)`
- `map(<TYPE>)`：映射对象，例如 `map(string)`
- `object({<ATTR NAME> = <TYPE>, ... })`：对象，例如 `object({ name = string, age = number })`
- `tuple([<TYPE>, ...])`：元组，例如 `tuple([string, number, bool])`

```hcl
variable "image_id" {
  type = string
}

variable "availability_zone_names" {
  type    = list(string)
  default = ["us-west-1a"]
}

variable "docker_ports" {
  type = list(object({
    internal = number
    external = number
    protocol = string
  }))
  default = [
    {
      internal = 8300
      external = 8300
      protocol = "tcp"
    }
  ]
}
```


### Module 示例

模块用来存储可复用的代码，如果在每一个 terraform 项目中都写一遍相同的代码，会导致代码重复。这个时候就可以使用模块，

Module 是有层级的，例如：

```bash
terraformpro
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── modules
│   ├── module1
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   ├── module2
│   ├── module3
```

`main.tf`：

```hcl
# call module1 which has 2 variables
module "module1" {
  source = "./modules/module1" # 指定模块的路径
  basename = "examplemodule1" # 设置模块变量的值
  location = "West Europe" # 设置模块变量的值
}

# call module2 which has 3 variables
module "module2" {
  source = "./modules/module2"
  basename = "examplemodule2"
  # resource_group_name 是 module1 创建完以后返回的，虽然我们可以知道 module1 创建的 resource group 名称是 ExampleRG
  # 但是在 module2 中并不想写死
  # module1 的 output 文件输出了 resource_group_name
  resource_group_name = module.module1.resource_group_name
  location = "West Europe"
}
```

`module1/outputs.tf`：

```hcl
# 模块输出 resource_group_name
output "resource_group_name" {
  # <资源类型>.<资源名称>.<key>
  value = azurerm_resource_group.resourcegroup.name
}
```

**一个 output 属性只能定义一个 value**。


### For 循环示例

```hcl
resource "azurerm_resource_group" "resourcegroup" {
  name     = var.resource_group_name
  location = var.location # 引用变量，使用 var.<变量名>
}

resource "azurerm_virtual_network" "vnet" {
  name                = "ExampleVNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name # 不使用 var.resource_group_name，因为创建顺序是无序的，
                                                                  # 直接使用，可能会报错，因为 vnet 依赖 resource group，而 resource group 没有创建完成，var.resource_group_name 这个 resource group 还不存在
}

resource "azurerm_subnet" "subnet" {
    for_each = var.subnets # for each 变量 subnets，遍历里面每一个 instance
    resource_group_name  = azurerm_resource_group.resourcegroup.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    name                 = each.value["name"] # 提取变量 subnets 中的一个元素的 name 的值
    address_prefixes     = each.value["address_prefixes"] # 提取变量 subnets 中的一个元素的 address_prefixes 的值
}
```

`variables.tf`：

```hcl
variable "subnets" {
  type = map(any)
  default = {
    subnet_1 = {
      name = "Subnet1"
      address_prefixes = ["10.0.0.0/24"]  # []代表列表，一个或多个值
    }
    subnet_2 = {
      name = "Subnet2"
      address_prefixes = ["10.0.1.0/24"]
    }
    subnet_3 = {
      name = "Subnet3"
      address_prefixes = ["10.0.2.0/24"]
    }
    bastion_subnet = {
        name = "AzureBastionSubnet" # bastion 的 subnet 必须是这个名字
        address_prefixes = ["10.0.250.0/24"]
    }
  }
}
```

### Data Sources 示例

Provider 的文档中，不仅有 Resource，还有 Data Source。例如 EC2 目录下有 Resources，还有 Data Sources。


```hcl
data "aws_vpc" "exist_vpc" {
  # 这里可以定义的过滤条件，告诉 aws，按照什么条件去查找，输出一个符合条件的 VPC
  # filter {}
  default = true # 表示如果没有找到符合条件的 VPC，就使用默认的 VPC
}
```

```hcl
resource "aws_subnet" "dev_subnet" {
    vpc_id = data.aws_vpc.exist_vpc.id
    cidr_block = "10.0.1.0/24"  # 不能和默认的 VPC 下的子网的 CIDR 冲突
    availability_zone = "us-east-1a"
}
```



## 身份认证

如何证明你有权限在对应的云平台上操作。**Terraform 本身不处理认证，而是委托给下载的 Provider 插件**，并由插件遵循对应云平台的认证标准。

| 云平台 | 认证方式 (推荐顺序) | Terraform Provider 如何获取凭证 |
| --- | --- | --- |
| AWS | 1. IAM 角色 (用于 EC2/ECS 等) <br />2. 共享凭证文件 (~/.aws/credentials) <br />3. 环境变量 <br />4. 硬编码 (极不推荐) | Provider 会使用 AWS SDK，自动按照标准 AWS CLI 的认证流程查找凭证。 |
| Azure | 1. 环境变量 (ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID) <br />2. CLI 认证 (az login) | Provider 使用 Azure SDK，支持环境变量或自动继承已登录的 Azure CLI 的认证上下文。 |
| Google Cloud | 1. 应用默认凭证 (ADC) - gcloud auth application-default login <br />2. 服务账户密钥文件 <br />3. 环境变量 | Provider 使用 Google Cloud SDK，自动查找应用默认凭证或环境变量指定的密钥文件。 |
| Kubernetes | 1. 环境变量 (KUBERNETES_SERVICE_HOST, KUBERNETES_SERVICE_PORT) <br />2. 配置文件 (~/.kube/config) | Provider 使用 Kubernetes 客户端库，自动查找环境变量或配置文件指定的集群信息。 |

### AWS

1. **静态凭证** (Static Credentials) - 不推荐用于生产

**硬编码 (极不推荐，最不安全)**，会被提交到 Git 仓库：

```hcl
provider "aws" {
  region     = "us-west-2"
  access_key = "my-access-key"
  secret_key = "my-secret-key"
}
```

**环境变量**：

```bash
export AWS_ACCESS_KEY_ID="anaccesskey"
export AWS_SECRET_ACCESS_KEY="asecretkey"
export AWS_REGION="us-west-2"
terraform plan
```

```hcl
provider "aws" {}
```

**共享凭证文件**：

`export` 环境变量的方式只在当前 Terminal 生效，关闭 Terminal 后就失效了。想要全局生效，使用凭证文件 `~/.aws/credentials`。

```hcl
provider "aws" {
  region = "us-west-2"
}
```

凭证文件：

当你运行 `aws configure` 后，凭证会保存在 `~/.aws/credentials` 中。Terraform 会自动读取这个文件。

```ini
# ~/.aws/credentials
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

对应的 `~/.aws/config` 文件定义区域：

```ini
# ~/.aws/config
[default]
region = us-east-1
```

**避免使用静态凭证，尤其是硬编码**。如果必须使用，请仅用于个人测试账户，并确保 terraform 文件绝不包含凭证并提交到 Git。

2. **IAM 角色和临时安全凭证** (IAM Roles & Temporary Security Credentials) 

这是 AWS 和 Terraform 推荐的**最佳实践**，因为它提供了更高的安全性。凭证是临时的（默认最多 1 小时），过期后自动失效，无需轮换。

**通过环境变量提供临时凭证**：

临时凭证除了 Access Key 和 Secret Key，还有一个 Session Token。

```bash
export AWS_ACCESS_KEY_ID="ASIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export AWS_SESSION_TOKEN="your-very-long-session-token"
terraform plan
```

**在共享凭证文件中配置临时凭证**：

在 `~/.aws/credentials` 中，可以为一个 Profile 配置临时凭证：

```ini
[default]
aws_access_key_id = ASIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
aws_session_token = your-very-long-session-token
```

3. IAM 实例配置文件

当 Terraform 运行在 **AWS 资源内部**时（例如在 EC2 实例上），这是最安全、最推荐的方式。

原理：
1. 你创建一个 IAM 角色（Role）并授予它必要的权限。
2. 你将这个角色附加（Attach）到 EC2 实例上（通过实例配置文件 Instance Profile）。
3. EC2 实例上的应用程序（包括 Terraform）可以通过内网的实例元数据服务 (IMDS) 自动获取该角色的临时安全凭证。
4. Terraform AWS Provider 会自动发现并使用这些凭证，你无需做任何配置。

## 状态

terraform 会将资源的状态保存在状态文件中。默认是 `terraform.tfstate`。这是一个 JSON 文件。

每当更新资源后，terraform 会更新状态文件。

如果删除了所有资源，那么 `resources` 会是一个空数组。

### terraform.tfstate.backup

`terraform.tfstate.backup` 是一个备份文件，是 **Terraform 在覆盖当前状态文件 (terraform.tfstate) 之前自动创建的备份副本**。它的核心作用是充当“后悔药”，让你在操作失败或出现意外时，能够恢复到操作前的已知状态。

terraform.tfstate.backup 会在你执行任何会修改状态文件的 Terraform 命令时生成。具体来说，当以下两个条件同时满足时：

1. 执行了会修改状态文件的操作：
   - `terraform apply`（创建、更新或销毁资源）
   - `terraform destroy`
   - `terraform refresh` （替代品 `apply -refresh-only` 也会）
   - 使用 `-target` 参数的上述命令
   - `terraform import`
2. **使用本地后端** (local backend)：即你的状态文件 (terraform.tfstate) 存储在本地磁盘上。如果你使用了远程后端（如 S3、Azure Storage），Terraform 通常不会在本地生成 .backup 文件，因为备份和版本控制由后端自己处理（例如 S3 的对象版本控制）。

#### 它有什么用？

这是一个**灾难恢复**机制。

1. 操作失败或中断：
   - `apply` 操作在执行中途失败（如网络中断、权限突然失效、配额不足）。
   - 此时，部分资源可能已经被创建或修改，而另一部分没有。
   - 结果：状态文件 (`terraform.tfstate`) 可能处于一个不完整、不一致或损坏的状态，因为它只记录了一部分变更。
2. 意外后果：
   - `apply` 操作成功完成了，但引入了一个你未曾预料到的严重问题（例如，错误地覆盖了一个关键配置）。
   - 结果：状态文件是最新的，但基础设施的状态是错误的。

在这些情况下，可以检查 .backup 文件，了解操作开始前基础设施的状态。从而进行问题诊断。

#### 限制

1. **它只备份前一个状态**，对于完整的历史跟踪，要使用：
   - 版本控制工具（如 Git），手动将 terraform.tfstate 和 .backup 文件提交到 Git，但这非常不推荐，因为状态文件包含敏感信息。
   - 远程后端（如 S3、Azure Storage），**最佳实践**。每次状态更新都会在云端保存一个历史版本，你可以随时回滚到任何历史版本。
2. 远程后端的行为不同：对于**远程后端，本地不会生成 `.backup`**，但后端本身提供了更强大的版本历史、状态锁定和恢复功能。应该优先使用远程后端。

### terraform.tfstate 什么时候更新

成功执行 `terraform apply` 或 `terraform destroy` 命令后更新。

### 远程后端

当团队多个人在使用时，每个人都会在本地执行 Terraform 命令, 或者正在将 Terraform 集成到 Jenkins 中。存在多个创建状态的地方.

如何共享状态?

远程后端存储.

Terraform 引入了远程状态存储机制，也就是 Backend。Backend 是一种抽象的远程存储接口，如同 Provider 一样，Backend 也支持多种不同的远程存储服务：

- local
- remote
- azurerm
- consul
- cos
- gcs
- http
- kubernetes
- oss
- pg
- s3

状态锁是指，当针对一个 tfstate 进行变更操作时，可以针对该状态文件添加一把全局锁，确保同一时间只能有一个变更被执行。

不同的 Backend 对状态锁的支持不尽相同，实现状态锁的机制也不尽相同，例如 consul Backend就通过一个 `.lock` 节点来充当锁。`s3` Backend 则需要用户传入一个 Dynamodb 表来存放锁信息，而 tfstate 文件被存储在 S3 存储桶里。

```hcl
terraform {
  required_version = "1.13.0"
  backend "s3" {
    bucket = "myapp-terraform-state-bucket"
    key    = "myapp/terraform.tfstate"
    region = "eu-west-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
```

需要先去 aws 创建一个 s3 的 bucket. 名字是 `my-terraform-state-bucket` 然后在 bucket 中创建一个文件夹. 文件夹的名称就是 `myapp/terraform.tfstate`.

bucket settings for Block Public Access:
- Block all public access

Bucket Versioning: bucket 版本控制,每次文件更改都会生成一个版本,可以回滚.
- Enable

Default encryption: 开启默认加密, 可以防止数据泄露.
- Disable

Create. 之后就创建了一个空桶




### state 命令


`terraform state` 命令用于查看和管理 Terraform 状态文件。

- `terraform state list`：列出状态文件中的所有资源。
- `terraform state show <resource>`：显示指定资源的详细信息。这在调试、查找特定信息（如 IP 地址、ARN）时极其有用。
- `terraform state rm <resource>`：从状态文件中删除指定资源。但不会销毁实际的云资源。
   - 如果有人绕过 Terraform 在控制台上删除了资源，状态文件中就会留下一个“幽灵”记录。`terraform plan` 会报错说资源找不到。这时可以用 `state rm` 来清理这个无效记录。
   - `terraform state rm aws_instance.web` Terraform 会“忘记”它曾管理过这个 EC2 实例，但该实例仍在 AWS 中运行。下次 `apply` 时，Terraform 会试图创建一个新的 `aws_instance.web`（如果配置还在），导致资源冲突。
- `terraform state pull`：从远程后端拉取最新状态。`terraform state pull > state.json` 主要用于编程式处理状态文件内容，或者用于调试复杂问题。
- `terraform state push`：将本地状态推送到远程后端。
- `terraform state mv <source> <destination>`：移动资源在状态文件中的位置。不会影响真实的基础设施。云上的资源完好无损，只是 Terraform 管理它的“名字”变了。你必须提前在代码中配置好目标资源块。这个命令**只修改状态，不修改代码**。

### 运维工作流

#### 修复一个被手动修改的资源

1. **发现问题**：`terraform plan` 报告说有漂移（drift），比如安全组的规则被人在 AWS 控制台上改了。
2. 先使用 `terraform state show <resource>` **查看资源的当前状态**。
3. **查看真实状态**：去 AWS 控制台确认安全组的真实规则。
4. **修复 drift**：根据 AWS 控制台的真实规则，修改 Terraform 配置文件。
5. 执行 `terraform apply` 应用变更。
6. 确认资源已被正确创建或更新。

#### 重命名资源

假设我们有一个简单的 EC2 实例资源：

```hcl
# main.tf (原始代码)
resource "aws_instance" "old_name" {
  ami           = "ami-123456"
  instance_type = "t3.micro"
}
```

想把资源标识符从 old_name 改为 new_name。

1. 首先，修改代码。将 `main.tf` 中的资源块改名。`resource "aws_instance" "new_name"`。
2. 执行 `state mv` 命令。告诉 Terraform 状态文件中原来的那个资源现在由新的名字来管理。
3. 最后，验证。运行 terraform plan。输出应该显示 No changes. 这意味着基础设施不需要任何变更，只是状态文件的内部记录更新了。

如果直接改代码而不运行 `state mv`，Terraform 会计划销毁 `aws_instance.old_name` 并创建 `aws_instance.new_name`。


## 其他常用命令


## workspace

**Workspaces 隔离的是 State，而不是代码或变量**。**快速、轻量地创建配置相同但状态隔离的环境**。

它非常适用于短期存在的环境，如**功能分支开发环境、临时测试环境，或者需要快速复制一套完整基础设施的场景**。

### 使用场景

你有一套定义好的基础设施代码（例如：1个VPC、2个EC2实例、1个RDS数据库）。现在你需要为功能开发、测试和预发布各部署一套完全一样但完全隔离的环境。

```bash
# 创建新工作区
terraform workspace new feature-login
terraform workspace new staging
terraform workspace new preprod

# 切换工作区并部署
terraform workspace select feature-login
terraform apply -var-file=feature.tfvars

terraform workspace select staging
terraform apply -var-file=staging.tfvars

terraform workspace select preprod
terraform apply -var-file=preprod.tfvars
```

### 如何在工作区之间实现差异配置？

1. **使用输入变量和条件表达式**。

2. **使用不同的变量文件**（`.tfvars`）（推荐）：

```bash
terraform workspace select dev
terraform apply -var-file="dev.tfvars"

terraform workspace select prod
terraform apply -var-file="prod.tfvars"
```

### 限性和风险

容易人为失误：很容易忘记切换工作区。你可能以为自己身在 dev，但实际上在 prod，一个 terraform destroy 就会导致灾难性后果。必须时刻使用 terraform workspace show 确认当前工作区。

代码复杂性：在代码中嵌入大量 terraform.workspace 的逻辑会使配置变得复杂和难以理解，降低了代码的可读性和可维护性。

### 什么时候应该避免使用 Workspaces？

对于严格隔离的生产环境（Production），最佳实践通常不是使用 Workspaces，而是使用以下更强大的隔离方式：

独立的 Terraform 配置目录：为 prod 和 dev 创建完全独立的代码目录。这提供了最强的隔离性。

不同的版本控制分支：main 分支代表生产状态，dev 分支用于开发。

不同的云账户（AWS Account / Azure Subscription）：这是黄金标准。通过物理账户边界实现绝对的权限和资源隔离。使用 Terraform 云提供商别名或不同的后端来管理不同账户的资源。

不同的 Terraform 后端：为每个环境使用完全独立的 S3 桶和 DynamoDB 表来存储状态。

## backend

backend 是 Terraform 用来存储状态文件的地方。

