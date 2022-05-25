terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
# Configure the AWS Provider

provider "aws" {
  region = "us-west-2"
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"

  name = "vpc_KK"
  cidr = "192.168.0.0/16"

  azs             = ["us-west-2a"]
  private_subnets = ["192.168.0.0/18", "192.168.64.0/18"]
  public_subnets  = ["192.168.128.0/18", "192.168.192.0/18"]

  enable_nat_gateway = true
}

resource "aws_security_group" "sg_KK" {
  name   = "sg_KK"
  vpc_id = module.vpc.vpc_id
  //  vpc_id = data.aws_vpc.default.id

  dynamic "ingress" {
    for_each = ["80", "443"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["162.158.222.152/32"]
  }
}


module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "EC2_instance_KK"

  ami                    = "ami-0ca285d4c2cda3300"
  instance_type          = "t3.micro"
  subnet_id              = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids = [aws_security_group.sg_KK.id]

  user_data = <<EOF
#!/bin/bash
set -ex
yum update -y
yum install -y httpd.x86_64
systemctl start httpd.service
systemctl enable httpd.service
echo "Hello World from $(hostname -f)" > /var/www/html/index.html
EOF
}
