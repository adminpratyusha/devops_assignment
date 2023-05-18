terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
provider "aws" {
  region = "${var.region}"
}


resource "aws_vpc" "dev-vpc" {
  cidr_block = "${var.cidr}"
  tags = {
    Name = "dev"
  }
}
 resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.dev-vpc.id
}

resource "aws_route_table" "dev-route-table" {
  vpc_id = aws_vpc.dev-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "dev-rt"
  }
}

resource "aws_subnet" "dev-sub" {
  vpc_id     = aws_vpc.dev-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "dev-sub"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.dev-sub.id
  route_table_id = aws_route_table.dev-route-table.id
}

resource "aws_security_group" "allow_web" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.dev-vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.dev-vpc.cidr_block]
  }
  ingress {
    description      = "http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.dev-vpc.cidr_block]
  }
  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.dev-vpc.cidr_block]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}


resource "aws_instance" "myec2" {

  ami= "${var.ami}" 
  instance_type = "${var.instance_type}"
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  subnet_id = aws_subnet.dev-sub.id
  associate_public_ip_address =  "${var.assign_public_ip}"

   tags = {
    Name = "terraform ec2"
  }

}