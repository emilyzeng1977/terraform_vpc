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
    Name = "tf_tom"
  }
}
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  tags = var.tag_name
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags                    = var.tag_name
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags   = var.tag_name
}
resource "aws_route_table" "custom" {
  vpc_id = aws_vpc.main.id
  tags   = var.tag_name
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}
resource "aws_route_table_association" "custom" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.custom.id
}

resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.main.id
  tags   = var.tag_name
  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_instance" "ec2_public" {
  ami           = "ami-020d764f9372da231"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.sg.id]
  key_name      = "key_tom23"
  subnet_id     = aws_subnet.public_subnet.id
  tags          = var.tag_name
}

output "vpc_id" {
  value = aws_vpc.main.id
}
