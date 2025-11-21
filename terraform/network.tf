################################################################################
# VPC AND INTERNET GATEWAY
################################################################################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "coalfire-sre-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "coalfire-sre-igw"
  }
}

################################################################################
# SUBNETS
################################################################################

# Application subnet A in AZ1 (private)
resource "aws_subnet" "app_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_subnet_a_cidr
  availability_zone = "us-east-1a"

  tags = {
    Name = "app-subnet-a-private-az1"
    Tier = "application"
  }
}

# Application subnet B in AZ2 (private)
resource "aws_subnet" "app_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_subnet_b_cidr
  availability_zone = "us-east-1b"

  tags = {
    Name = "app-subnet-b-private-az2"
    Tier = "application"
  }
}

# Management subnet in AZ1 (public)
resource "aws_subnet" "mgmt" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.mgmt_subnet_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "mgmt-subnet-public-az1"
    Tier = "management"
  }
}

# Backend subnet in AZ2 (private)
resource "aws_subnet" "backend" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.backend_subnet_cidr
  availability_zone = "us-east-1b"

  tags = {
    Name = "backend-subnet-private-az2"
    Tier = "backend"
  }
}

################################################################################
# ROUTE TABLE FOR PUBLIC MANAGEMENT SUBNET
################################################################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "mgmt_assoc" {
  subnet_id      = aws_subnet.mgmt.id
  route_table_id = aws_route_table.public.id
}

################################################################################
# SECURITY GROUPS
################################################################################

# Security group for the Application Load Balancer
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP from the internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

# Security group for application EC2 instances (Auto Scaling Group)
resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Allow HTTP from ALB and SSH from management subnet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description = "SSH from management subnet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.mgmt.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-sg"
  }
}

# Security group for the management EC2 instance
resource "aws_security_group" "mgmt_sg" {
  name        = "mgmt-sg"
  description = "SSH only from a trusted CIDR"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mgmt-sg"
  }
}
