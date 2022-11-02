terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "app_server" {
  ami           = "ami-0b9a603c10937a61b"
  instance_type = "t2.micro"

  tags = {
    Name = "ExampleAppServerInstance"
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  tags = {
    Name = "kubernetes-the-hard-way"
  }
}

resource "aws_subnet" "test" {

  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "kubernetes"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "kubernetes"
  }
}

resource "aws_route_table" "example" {
  vpc_id = aws_vpc.main.id


  tags = {
    Name = "kubernetes"
  }
}

resource "aws_route" "test" {
  gateway_id = aws_internet_gateway.gw.id  
  route_table_id            = aws_route_table.example.id
  destination_cidr_block    = "0.0.0.0/0"
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.test.id
  route_table_id = aws_route_table.example.id
}

resource "aws_security_group" "kubernetes_sg" {
  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.sg_rules
    content {
      to_port     = ingress.value["to_port"]
      from_port   = ingress.value["from_port"]
      protocol    = ingress.value["protocol"]
      cidr_blocks = ingress.value["cidr_blocks"]
    }
  }
}


resource "aws_lb" "test" {
  name               = "kubernetes"
  internal           = false
  load_balancer_type = "network"
  subnets            = ["10.0.1.0/24"]
  enable_deletion_protection = true
}

resource "aws_lb_target_group" "kubernetes" {
    name = "kubernetes"
    protocol = "tcp"
    port = 6443
    vpc_id = aws_vpc.main.id
    target_type = "ip"

    depends_on = [
    aws_lb.test
  ]
}

resource "aws_lb_target_group_attachment" "kubernetes" {
    for_each = toset(var.ipaddrs)
    port = 6443
    target_group_arn = aws_lb.test.arn
    target_id = each.value
}



resource "aws_lb_listener" "kubernetes" {
    load_balancer_arn = aws_lb.test.arn
    protocol = "tcp"
    port = 443
    default_action {
      type="forward"
      target_group_arn = aws_lb.test.arn
    }
}
