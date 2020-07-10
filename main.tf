provider "aws" {
  profile       = "default"
  region = "ap-southeast-2"
}
variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}
variable "tag_name" {
  type = object({
    Name = string
  })
  default = {
    Name = "tf_zyc"
  }
}
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr_block
  #instance_tenancy = "dedicated"
  tags = var.tag_name
}
resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  tags = var.tag_name
}
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  tags = var.tag_name
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = var.tag_name
}
resource "aws_route_table" "r" {
  vpc_id = aws_vpc.main.id
  tags = var.tag_name
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}
resource "aws_route_table_association" "custom" {
  subnet_id = aws_subnet.main.id
  route_table_id = aws_route_table.r.id
}
resource "aws_eip" "nat" {
  vpc      = true
  tags = var.tag_name
}
resource "aws_nat_gateway" "default" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id = "${aws_subnet.main.id}"
  tags = var.tag_name
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.default.id
  }
  tags = var.tag_name
}
resource "aws_route_table_association" "private" {
    subnet_id = aws_subnet.private.id
    route_table_id = aws_route_table.private.id
}
resource "aws_security_group" "ecs_sg" {
    vpc_id      = aws_vpc.main.id

    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    ingress {
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    egress {
        from_port       = 0
        to_port         = 65535
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "container" {
  ami           = "ami-020d764f9372da231"
  instance_type = "t2.micro"
  key_name = "emily_keypairs"
  subnet_id = aws_subnet.main.id
  tags = var.tag_name
}
output "vpc_id" {
  value = aws_vpc.main.id
}
output "vpc_owner_id" {
  value = aws_vpc.main.owner_id
}
output "subnet_id" {
  value = aws_subnet.main.id
}