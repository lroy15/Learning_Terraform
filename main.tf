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
  name = "kuber_sg"

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
  subnets            = [aws_subnet.test.id]
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "kubernetes" {
    name = "kubernetes"
    protocol = "TCP"
    port = 6443
    vpc_id = aws_vpc.main.id
    target_type = "ip"

    depends_on = [
    aws_lb.test
  ]
}

resource "aws_lb_target_group_attachment" "kubernetes" {
    count = 3
    port = 6443
    target_group_arn = aws_lb_target_group.kubernetes.id
    target_id = "10.0.1.1${count.index}"
}



resource "aws_lb_listener" "kubernetes" {
    load_balancer_arn = aws_lb.test.arn
    protocol = "TCP"
    port = 443
    default_action {
      type="forward"
      target_group_arn = aws_lb_target_group.kubernetes.arn
    }
}


resource "aws_instance" "kubernetes" {

    count = 3
    ami     = "ami-01d08089481510ba2"
    key_name    = "kubernetes"
    instance_type    = "t3.micro"
    private_ip = "10.0.1.1${count.index}"
    subnet_id = aws_subnet.test.id
    associate_public_ip_address = true
    vpc_security_group_ids = [aws_security_group.kubernetes_sg.id]
    user_data = "name=controller-${count.index}"
    ebs_block_device {
            device_name = "/dev/sda1"
            volume_size = 50
    }
    
}

resource "aws_instance" "kubernetes_worker" {
    count = 3
    ami = "ami-01d08089481510ba2"
    associate_public_ip_address = true
    key_name = "kubernetes"
    vpc_security_group_ids = [aws_security_group.kubernetes_sg.id]
    instance_type    = "t3.micro"
    private_ip = "10.0.1.2${count.index}"
    subnet_id = aws_subnet.test.id
    user_data {
        name = "worker-${count.index}|pod-cidr=10.200.${count.index}.0/24"
    }
    ebs_block_device {
            device_name = "/dev/sda1"
            volume_size = 50
    }
    tags = {
        "Name"="worker-${count.index}"
    }
}