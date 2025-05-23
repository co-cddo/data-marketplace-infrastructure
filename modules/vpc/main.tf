resource "aws_vpc" "vpc_dm_eks" {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.project_code}-${var.env_name}-vpc"
  }
}
data "aws_availability_zones" "available" {}

// What if the number of subnets differs from the number of availability zones?
// Code needs to be refactored/improved for private and public subnet resources!
resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnets)

  cidr_block        = var.public_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.vpc_dm_eks.id
  tags = {

    Name                                        = "${var.project_code}-${var.env_name}-publicsub-${1 + count.index}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/elb"                    = "1"
  }
}

resource "aws_subnet" "private_subnets" {

  count             = length(var.private_subnets)
  cidr_block        = var.private_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.vpc_dm_eks.id
  tags = {
    Name                                        = "${var.project_code}-${var.env_name}-privatesub-${1 + count.index}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

//Create an Internet Gateway 
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc_dm_eks.id
  tags = {
    "Name" = "${var.project_code}-${var.env_name}-igw"
  }
}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc_dm_eks.id

  tags = {
    Name = "${var.project_code}-${var.env_name}-private-rtb"
  }
}

resource "aws_route" "nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_one.id
}

resource "aws_route_table_association" "private-subnet-1" {
  subnet_id      = aws_subnet.private_subnets[0].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private-subnet-2" {
  subnet_id      = aws_subnet.private_subnets[1].id
  route_table_id = aws_route_table.private.id
}
//associate the public subnets to the IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc_dm_eks.id

  tags = {
    "Name" = "${var.project_code}-${var.env_name}-public-rtb"
  }
}
resource "aws_route" "to-igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}


resource "aws_route_table_association" "public-subnet-1" {
  subnet_id      = aws_subnet.public_subnets[0].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-subnet-2" {
  subnet_id      = aws_subnet.public_subnets[1].id
  route_table_id = aws_route_table.public.id
}

//Create Elastic IP for the NAT Gateway
resource "aws_eip" "Nat-Gateway-EIP" {
  depends_on = [
    aws_route_table_association.public-subnet-1
  ]
  domain = "vpc"
  tags = {
    "Name" = "${var.project_code}-${var.env_name}-ElasticIP"
  }
}

resource "aws_nat_gateway" "nat_gateway_one" {
  depends_on = [
    aws_eip.Nat-Gateway-EIP,
    aws_internet_gateway.internet_gateway
  ]

  # Allocating the Elastic IP to the NAT Gateway!
  allocation_id = aws_eip.Nat-Gateway-EIP.id

  # Associating it in the Public Subnet!
  subnet_id = aws_subnet.public_subnets[0].id
  tags = {
    Name = "${var.project_code}-${var.env_name}-NAT"

  }
}



#create peering
data "aws_vpc" "default" {
  default = true
}

data "aws_route_table" "default_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "tag:Name"
    values = ["private-route-table"]
  }
}

resource "aws_vpc_peering_connection" "peer" {
  vpc_id      = data.aws_vpc.default.id
  peer_vpc_id = aws_vpc.vpc_dm_eks.id
  auto_accept = true

  tags = {
    Name = "default-to-${var.project_code}-${var.env_name}"
  }
}

resource "aws_route" "default_to_new" {
  route_table_id            = data.aws_route_table.default_private.id
  destination_cidr_block    = aws_vpc.vpc_dm_eks.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "new_to_default" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
