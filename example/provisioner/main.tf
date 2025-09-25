terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "eu-west"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable my_ip {}
variable instance_type {}
variable public_key_location {}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id     = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name = "${var.env_prefix}-subnet-1"
  }
}

resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name = "${var.env_prefix}-rtb"
  }
}

# 使用默认的 main route table
# 可以利用 terraform state show aws_vpc.myapp-vpc 查看，得到 default_route_table_id
# resource "aws_default_route_table" "default-rtb" {
#   default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.myapp-igw.id
#   }
#   tags = {
#     Name = "${var.env_prefix}-main-rtb"
#   }
# }

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id
}

# 使用默认的 main route table 时，不需要关联路由表，所有子网会自动关联
resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.myapp-route-table.id
}

resource "aws_security_group" "myapp-sg" {
  name = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    # 打开一个 0 ~ 1000 端口范围
    # from_port = 0
    # to_port = 1000

    # 允许 SSH 访问
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = [] # 允许所有前缀列表
  }
  tags = {
    Name = "${var.env_prefix}-sg"
  }
}

# 使用默认的 security_group
# resource "aws_default_security_group" "default-sg" {
#   vpc_id = aws_vpc.myapp-vpc.id

#   ingress {
#     from_port = 22
#     to_port = 22
#     protocol = "tcp"
#     cidr_blocks = [var.my_ip]
#   }

#   ingress {
#     from_port = 8080
#     to_port = 8080
#     protocol = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port = 0
#     to_port = 0
#     protocol = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#     prefix_list_ids = [] # 允许所有前缀列表
#   }
#   tags = {
#     Name = "${var.env_prefix}-default-sg"
#   }
# }

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]
  # 在控制台 EC2 -> AMI -> 根据 ami id 搜索 -> 查看 owner,AMI name
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

# for test
output "aws_ami_id" {
  value = data.aws_ami.latest-amazon-linux-image.id
}

output "ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}

resource "aws_instance" "myapp-server" {
  # ami 是 Amazon Machine Image，是 EC2 实例的操作系统镜像
  # 不同的 region 有不同的 ami,就算是同一个镜像,id 可能不同
  # 新的 ami 发布,也会导致 ami id 变化,所以 hardcode ami id 是不可取的
  # 应该动态的获取最新的 ami id
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type # type of instance
  
  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  availability_zone = var.avail_zone
  
  associate_public_ip_address = true # 需要公网 IP

  # 登录 EC2 server
  # 需要先配置 Key pair,下载夏利以后,最好放在 ~/.ssh 目录下
  # 修改下载的 server-key-pair.pem 文件的权限 chmod 400, 必须的步骤,否则 aws 拒绝访问
  key_name = "server-key-pair"

  # 公钥
  # key_name = aws_key_pair.ssh-key.server-key

  # 需要定义 provisioner 如何连接 server
  connection {
    type = "ssh"
    host = self.public_ip # self 指的是所在资源
    user = "ec2-user"
    private_key = file("~/.ssh/server-key-pair.pem")
  }

  # 方式 1
  # provisioner "remote-exec" {
  #   inline = [ 
  #     "export ENV=dev",
  #     "mkdue newdir"
  #   ]
  # }

  # 方式 2
  # 需要 entry-script.sh 脚本在远端机器,所以需要先拷贝文件
  # file 可以在本地拷贝文件到远端机器
  provisioner "file" {
    source = "entry-script.sh"
    destination = "/home/ec2-user/entry-script-on-ec2.sh"
  }
  # remote-exec 可以在远端机器执行命令,在资源创建之后
  provisioner "remote-exec" {
    script = file("entry-script-on-ec2.sh")
  }
  # local-exec 可以在本地执行命令,在资源创建之后
  provisioner "local-exec" {
    command = "echo 'hello world'"
  }

  # 如果要拷贝文件到多台机器, 可以用下面的方式
  # 将 connecting 放在 provisioner 块中
  # provisioner "file" {
  #   source = "entry-script.sh"
  #   destination = "/home/ec2-user/entry-script-on-ec2.sh"

  #   connection {
  #     type = "ssh"
  #     host = self.public_ip # self 指的是所在资源
  #     user = "ec2-user"
  #     private_key = file("~/.ssh/server-key-pair.pem")
  #   }
  # }


  tags = {
    Name = "${var.env_prefix}-server"
  }
}

# 配置使用本机公钥登录
# resource "aws_key_pair" "ssh-key" {
#   key_name = "server-key"
#   public_key = "${file(var.public_key_location)}"
# }


# 最后可以使用 ssh 登录 EC2 server
# -i 使用指定私钥文件登录
# ec2-user 是默认用户
# ssh -i ~/.ssh/server-key-pair.pem ec2-user@<public ip>
# 配置了本机公钥以后
# ssh -i ~/.ssh/id_rsa ec2-user@<public ip> # -i ~/.ssh/id_rsa 可以忽略
