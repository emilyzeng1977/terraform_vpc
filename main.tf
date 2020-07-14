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
  map_public_ip_on_launch = true
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

resource "aws_security_group" "ecs_sg" {
    vpc_id      = aws_vpc.main.id
    tags = var.tag_name
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
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }
}


resource "aws_ecs_cluster" "my_cluster" {
  name = "my_cluster_zyc"
}
resource "aws_ecs_task_definition" "my_first_task" {
  family                   = "my-first-task" # Naming our first task
  container_definitions    = <<DEFINITION
  [
    {
      "name": "my-first-task",
      "image": "004468876800.dkr.ecr.ap-southeast-2.amazonaws.com/nginx:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 512         # Specifying the memory our container requires
  cpu                      = 256         # Specifying the CPU our container requires
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_ecs_service" "my_first_service" {
  name            = "my-first-service"                             # Naming our first service
  cluster         = aws_ecs_cluster.my_cluster.id             # Referencing our created Cluster
  task_definition = aws_ecs_task_definition.my_first_task.arn # Referencing the task our service will spin up
  launch_type     = "FARGATE"
  desired_count   = 3 # Setting the number of containers we want deployed to 3
  network_configuration {
    assign_public_ip = true
    subnets          = [aws_subnet.main.id]
  }
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