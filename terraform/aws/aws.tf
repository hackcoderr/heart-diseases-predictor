// Provide Credentials
provider "aws" {
  region = "ap-south-1"
  profile = "hackcoderr"
}

// variable section
variable "environment_tag" {
  description = "Environment tag"
  default = "Production"
}

//Creating VPC
resource "aws_vpc" "vpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  tags = {
    Name = "aws-heart-disease-predictor-vpc"
    Environment = "${var.environment_tag}"
  }
}

//Creating Subnets
resource "aws_subnet" "subnet-1a" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "aws-heart-disease-predictor-sunbet"
    Environment = "${var.environment_tag}"
  }
}

//Creating Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "aws-heart-disease-predictor-internet-gateway"
  }
}

// Creating Route Table
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {

gateway_id = aws_internet_gateway.gw.id
    cidr_block = "0.0.0.0/0"
  }

    tags = {
    Name = "aws-heart-disease-predictor-route-table"
  }
}

// Route Table Association
resource "aws_route_table_association" "route-association" {
  subnet_id      = aws_subnet.subnet-1a.id
  route_table_id = aws_route_table.route_table.id
}

# creating a security group
resource "aws_security_group" "SG" {
  name = "Heart-SG"
  vpc_id = "${aws_vpc.vpc.id}"
  ingress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags ={
    Environment = "${var.environment_tag}"
    Name= "aws-heart-disease-predictor-SG"
  }

}


# launching instance 
resource "aws_instance" "AWS-HDP-instance" {
  ami    = "ami-0a9d27a9f4f5c0efc"
  count  = "3"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.subnet-1a.id}"
  vpc_security_group_ids = ["${aws_security_group.SG.id}"]
  key_name = "key"
 tags ={
    Environment = "${var.environment_tag}"
    Name= "AWS-HDP-Instance"
  }

}
