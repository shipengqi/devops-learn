resource "aws_subnet" "myapp-subnet-1" {
  vpc_id     = var.vpc_id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name = "${var.env_prefix}-subnet-1"
  }
}

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.env_prefix}-igw"
  }
}

# resource "aws_route_table" "myapp-route-table" {
#   vpc_id = aws_vpc.myapp-vpc.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.myapp-igw.id
#   }
#   tags = {
#     Name = "${var.env_prefix}-rtb"
#   }
# }

# 使用默认的 main route table
# 可以利用 terraform state show aws_vpc.myapp-vpc 查看，得到 default_route_table_id
resource "aws_default_route_table" "default-rtb" {
  default_route_table_id = var.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name = "${var.env_prefix}-main-rtb"
  }
}

# 使用默认的 main route table 时，不需要关联路由表，所有子网会自动关联
# resource "aws_route_table_association" "a-rtb-subnet" {
#   subnet_id = aws_subnet.myapp-subnet-1.id
#   route_table_id = aws_route_table.myapp-route-table.id
# }