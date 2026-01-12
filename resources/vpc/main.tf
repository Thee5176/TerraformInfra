##----------------------------VPC Level--------------------------
# VPC : define resource group
resource "aws_vpc" "main_vpc" {
  cidr_block                       = "172.16.0.0/16"
  instance_tenancy                 = "default"
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block  = true

  tags = {
    Name    = "${var.project_name}_vpc"
    Environment = var.environment_name
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Internet Gateway : allow access in VPC level
resource "aws_internet_gateway" "main_igw" {
  vpc_id     = aws_vpc.main_vpc.id
  depends_on = [aws_vpc.main_vpc]
  tags = {
    Name    = "${var.project_name}_igw"
    Environment = var.environment_name
  }
}

# Route Table :
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name    = "${var.project_name}_public_route"
    Environment = var.environment_name
  }
}

# Route : connect internet gateway with route table
resource "aws_route" "public_route" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_igw.id
  route_table_id         = aws_route_table.public_route.id
}

# IPv6 Route
resource "aws_route" "public_route_ipv6" {
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.main_igw.id
  route_table_id              = aws_route_table.public_route.id
}

# EC2 Subnet (Private)
resource "aws_subnet" "web_subnet" {
  vpc_id                          = aws_vpc.main_vpc.id
  cidr_block                      = cidrsubnet(aws_vpc.main_vpc.cidr_block, 8, 10 ) # 172.16.10.0/24
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main_vpc.ipv6_cidr_block, 8, 0)
  availability_zone               = data.aws_availability_zones.available.names[0]
  assign_ipv6_address_on_creation    = true

  tags = {
    Name    = "${var.project_name}_web_subnet"
    Environment = var.environment_name
  }

  lifecycle {
    # Avoid replacing subnets just because availability_zone changed in config
    ignore_changes = [availability_zone, cidr_block]
  }
}

# ALB Subnet (Public)
resource "aws_subnet" "alb_subnet" {
  count = min(length(data.aws_availability_zones.available.names), 2)

  vpc_id                          = aws_vpc.main_vpc.id
  cidr_block                      = cidrsubnet(aws_vpc.main_vpc.cidr_block, 8, 40 + count.index) # 172.16.40.0/24, 172.16.41.0/24
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main_vpc.ipv6_cidr_block, 8, 10 + count.index)
  availability_zone               = data.aws_availability_zones.available.names[count.index]
  assign_ipv6_address_on_creation    = true

  tags = {
    Name    = "${var.project_name}_alb_subnet_${count.index + 1}"
    Environment = var.environment_name
  }

  lifecycle {
    # Avoid replacing subnets when AZ mapping changes
    ignore_changes = [availability_zone, cidr_block]
  }
}

# DB Subnet (Private)
resource "aws_subnet" "db_subnet" {
  count = min(length(data.aws_availability_zones.available.names), 2)

  vpc_id                          = aws_vpc.main_vpc.id
  cidr_block                      = cidrsubnet(aws_vpc.main_vpc.cidr_block, 8, 60 + count.index) # 172.16.60.0/24, 172.16.61.0/24
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main_vpc.ipv6_cidr_block, 8, 20 + count.index)
  availability_zone               = data.aws_availability_zones.available.names[count.index]
  assign_ipv6_address_on_creation    = true

  tags = {
    Name    = "${var.project_name}_db_subnet_${count.index + 1}"
    Environment = var.environment_name
  }

  lifecycle {
    # Avoid replacing DB subnets just because AZ mapping changed
    ignore_changes = [availability_zone, cidr_block]
  }
}


# Public Table Association : connect EC2 subnet with public route table
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.web_subnet.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "alb_subnet_assocs" {
  count = length(aws_subnet.alb_subnet)

  subnet_id      = aws_subnet.alb_subnet[count.index].id
  route_table_id = aws_route_table.public_route.id
}

# RDS Table Association : connect RDS subnet with public route table
resource "aws_route_table_association" "db_subnet_assoc" {
  count = length(aws_subnet.db_subnet)  

  subnet_id      = aws_subnet.db_subnet[count.index].id
  route_table_id = aws_route_table.public_route.id
}