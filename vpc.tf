# Setting up VPC, subnets, internet_gateway, route_table, route_table_association

resource "aws_vpc" "test" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "Test VPC"
  }
}

resource "aws_subnet" "test_subnet_east_1a" {
  vpc_id     = aws_vpc.test.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Subnet us-east-1a"
  }
}

resource "aws_subnet" "test_subnet_east_1b" {
  vpc_id     = aws_vpc.test.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Subnet us-east-1b"
  }
}

resource "aws_internet_gateway" "test" {
  vpc_id = aws_vpc.test.id

  tags = {
    Name = "Test Internet Gateway"
  }
}

resource "aws_route_table" "test" {
    vpc_id = aws_vpc.test.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.test.id
    }

    tags = {
        Name = "Test Route Table"
    }
}

resource "aws_route_table_association" "us_east_1a_private" {
    subnet_id = aws_subnet.test_subnet_east_1a.id
    route_table_id = aws_route_table.test.id
}

resource "aws_route_table_association" "us_east_1b_private" {
    subnet_id = aws_subnet.test_subnet_east_1b.id
    route_table_id = aws_route_table.test.id
}