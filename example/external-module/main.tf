# 不是必须的,因为使用的是 hashicorp 官方的插件源
terraform {
  required_version = "1.13.0"
  backend "s3" {
    bucket = "my-terraform-state-bucket"
    key    = "myapp/terraform.tfstate"
    region = "eu-west-1" # 不是必须和 provider 中的 region 一致
  }

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

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  
  name = "my-vpc"
  cidr = var.vpc_cidr_block
  
  azs             = [var.avail_zone]
  # 暂时不需要
  # private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = [var.subnet_cidr_block]
  public_subnet_tags = {
    Name = "${var.env_prefix}-subnet-1"

  }
  # enable_nat_gateway = true
  # enable_vpn_gateway = true
  tags = {
    # Terraform = "true"
    # Environment = "dev"
    Name = "${var.env_prefix}-vpc"
  }
}

module "myapp-webserver" {
  source = "./modules/webserver"
  avail_zone = var.avail_zone
  env_prefix = var.env_prefix
  my_ip = var.my_ip
  instance_type = var.instance_type
  public_key_location = var.public_key_location
  image_name = var.image_name
  subnet_id = module.vpc.public_subnets[0]
  vpc_id = module.vpc.vpc_id
}

# 最后可以使用 ssh 登录 EC2 server
# -i 使用指定私钥文件登录
# ec2-user 是默认用户
# ssh -i ~/.ssh/server-key-pair.pem ec2-user@<public ip>
# 配置了本机公钥以后
# ssh -i ~/.ssh/id_rsa ec2-user@<public ip> # -i ~/.ssh/id_rsa 可以忽略
