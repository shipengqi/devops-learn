resource "aws_security_group" "myapp-sg" {
  name = "myapp-sg"
  vpc_id = var.vpc_id

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

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]
  # 在控制台 EC2 -> AMI -> 根据 ami id 搜索 -> 查看 owner,AMI name
  filter {
    name = "name"
    values = [var.image_name]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type # type of instance
  
  subnet_id = var.subnet_id
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  availability_zone = var.avail_zone
  
  associate_public_ip_address = true # 需要公网 IP

  # 公钥
  key_name = aws_key_pair.ssh-key.server-key

  # 方式 1
  provisioner "remote-exec" {
    inline = [ 
      "export ENV=dev",
      "mkdue newdir"
    ]
  }

  tags = {
    Name = "${var.env_prefix}-server"
  }
}

# 配置使用本机公钥登录
resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  public_key = "${file(var.public_key_location)}"
}