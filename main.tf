terraform {
  required_providers{
      aws = {
          source = "hashicorp/aws"
          version = "~> 4.17.1"
      }
  }
}

provider "aws"{
  
  profile = "default" 
  region = "us-west-2"

}

resource "aws_vpc" "kikise_vpc" {    
  cidr_block = "192.168.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.kikise_vpc.id
  cidr_block = "192.168.0.0/18" 
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.kikise_vpc.id
  cidr_block = "192.168.128.0/18" 
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.kikise_vpc.id  
}

resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]  
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.kikise_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  } 
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  } 
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "allow_http_https" {
  name        = "allow_http_https"
  description = "Allow HTTP/HTTPS inbound traffic"
  vpc_id      = aws_vpc.kikise_vpc.id

  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}


resource "aws_instance" "web" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.vpc_security_group_ids
  associate_public_ip_address = 
  iam_instance_profile        = e
  user_data                   = 

  tags = var.tags
}






