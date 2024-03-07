locals {
  # Everything is built around the AZs, increase one AZ that it will increase subnets, nats, eips and EKS nodes
  eks_availability_zones = toset([
    "us-east-1a",
  ])
}

# VPC
# Reference https://github.com/hashicorp/learn-terraform-provision-eks-cluster/blob/57e1156420c1f4893c7fc50da8b8dbf322961d34/main.tf#L26
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true # Defaults to true, but for reference since EKS nodes needs this to be true in order to work properly
  enable_dns_hostnames = true
  tags = {
    "Name" = "${local.project_name}-vpc"
  }
}

# VPC Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.project_name}-vpc-igw"
  }
}

# VPC Default route table with internet gateway route
resource "aws_default_route_table" "vpc_default_rt" {
  default_route_table_id = aws_vpc.main.main_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${local.project_name}-vpc-default-rt"
  }
}

# Need to be at least two subnets in two different AZs
# Public subnets
resource "aws_subnet" "eks_subnets_public" {
  for_each          = local.eks_availability_zones
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${index(tolist(local.eks_availability_zones), each.value) + length(local.eks_availability_zones) + 1}.0/24" # 254 IPs available to pods with this configuration
  availability_zone = each.value                                                                                                        # Ensure multi zones
  tags = {
    Name = "${local.project_name}-public_subnet_${each.value}"
    Tier = "Public"
  }
}

# Private subnets
resource "aws_subnet" "eks_subnets_private" {
  for_each          = local.eks_availability_zones
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${index(tolist(local.eks_availability_zones), each.value) + 1}.0/24" # 254 IPs available to pods with this configuration
  availability_zone = each.value                                                                 # Ensure multi zones
  tags = {
    Name = "${local.project_name}-private_subnet_${each.value}"
    Tier = "Private"
  }
}

# Route tables

## Private subnets route tables
## One route table per AZ, respectively on route table per private subnet
resource "aws_route_table" "private_subnet_rt" {
  for_each = local.eks_availability_zones
  vpc_id   = aws_vpc.main.id

  tags = {
    Name = "${local.project_name}-nat-${each.value}-rt"
  }
}

resource "aws_route_table_association" "private_subnet_rt_association" {
  for_each       = local.eks_availability_zones
  subnet_id      = aws_subnet.eks_subnets_private["${each.value}"].id
  route_table_id = aws_route_table.private_subnet_rt["${each.value}"].id
}

# NAT configuration

## One public IP per AZ
resource "aws_eip" "vpc_eip" {
  for_each = local.eks_availability_zones
  tags = {
    Name = "${local.project_name}-eip-${each.value}"
  }
}

## One nat per AZ, respectively one nat per public subnet
resource "aws_nat_gateway" "nat_gw" {
  for_each      = local.eks_availability_zones
  allocation_id = aws_eip.vpc_eip["${each.value}"].id
  subnet_id     = aws_subnet.eks_subnets_public["${each.value}"].id

  depends_on = [aws_eip.vpc_eip]

  tags = {
    Name = "${local.project_name}-nat-gw-public-subnet-${each.value}"
  }
}

# Routes
resource "aws_route" "nat_access" {
  for_each               = local.eks_availability_zones
  route_table_id         = aws_route_table.private_subnet_rt["${each.value}"].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw["${each.value}"].id
}