provider "aws" {
  profile = "default"
  region  = "ap-southeast-2"
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
  cidr_block = var.vpc_cidr_block
  #instance_tenancy = "dedicated"
  tags = var.tag_name
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  tags                    = var.tag_name
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  tags       = var.tag_name
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags   = var.tag_name
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.main.id
  tags   = var.tag_name
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "custom" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.r.id
}

#resource "aws_eip" "nat" {
#  vpc  = true
#  tags = var.tag_name
#}

resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main.id
  tags   = var.tag_name
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2_public_1" {
  ami           = "ami-020d764f9372da231"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.ec2_sg.id]
  key_name      = "emily_keypairs"
  subnet_id     = aws_subnet.main.id
  tags          = var.tag_name
}

resource "aws_instance" "ec2_public_2" {
  ami           = "ami-020d764f9372da231"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.ec2_sg.id]
  key_name      = "emily_keypairs"
  subnet_id     = aws_subnet.main.id
  tags          = var.tag_name
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
