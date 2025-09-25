# 不是必须的,因为使用的是 hashicorp 官方的插件源
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

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}

module "myapp-subnet" {
  source = "./modules/subnet"
  subnet_cidr_block = var.subnet_cidr_block
  avail_zone = var.avail_zone
  env_prefix = var.env_prefix
  vpc_id = aws_vpc.myapp-vpc.id
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
}

module "myapp-webserver" {
  source = "./modules/webserver"
  avail_zone = var.avail_zone
  env_prefix = var.env_prefix
  my_ip = var.my_ip
  instance_type = var.instance_type
  public_key_location = var.public_key_location
  image_name = var.image_name
  subnet_id = module.myapp-subnet.subnet.id
  vpc_id = aws_vpc.myapp-vpc.id
}

# 最后可以使用 ssh 登录 EC2 server
# -i 使用指定私钥文件登录
# ec2-user 是默认用户
# ssh -i ~/.ssh/server-key-pair.pem ec2-user@<public ip>
# 配置了本机公钥以后
# ssh -i ~/.ssh/id_rsa ec2-user@<public ip> # -i ~/.ssh/id_rsa 可以忽略
