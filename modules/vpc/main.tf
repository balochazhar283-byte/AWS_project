# =============================================================================
# modules/vpc/main.tf
# PURPOSE: Builds the network everything else lives in.
#
#   Internet
#      |
#  [Internet Gateway]
#      |
#  Public subnets (A,B)  -- hold the NAT Gateway; route 0.0.0.0/0 -> IGW
#      |
#  [NAT Gateway]  (lets private things reach the internet OUTBOUND only)
#      |
#  Private app subnets (A,B) -- Lambda; route 0.0.0.0/0 -> NAT
#
#  Private DB subnets (A,B)  -- RDS; NO route to the internet at all
#
# "count" creates one copy of a resource per list item; count.index is the
# position (0, 1, ...) so subnet A uses item 0 and subnet B uses item 1.
# =============================================================================

# --- The VPC itself -----------------------------------------------------------
# enable_dns_support / enable_dns_hostnames let resources resolve names such as
# the RDS endpoint (xxx.rds.amazonaws.com) to private IPs inside the VPC.
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.project_name}-vpc" }
}

# --- Internet Gateway: the door between the VPC and the public internet -------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.project_name}-igw" }
}

# --- Subnets -------------------------------------------------------------------
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = { Name = "${var.project_name}-public-${count.index == 0 ? "a" : "b"}" }
}

resource "aws_subnet" "private_app" {
  count = length(var.private_app_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = { Name = "${var.project_name}-private-app-${count.index == 0 ? "a" : "b"}" }
}

resource "aws_subnet" "private_db" {
  count = length(var.private_db_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_db_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = { Name = "${var.project_name}-private-db-${count.index == 0 ? "a" : "b"}" }
}

# --- NAT Gateway ---------------------------------------------------------------
# A NAT Gateway needs a fixed public IP (Elastic IP) and must sit in a PUBLIC
# subnet. One NAT (in public subnet A) keeps cost down; for production you would
# create one per AZ. depends_on makes sure the IGW exists first.
resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = { Name = "${var.project_name}-nat-eip" }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.main]

  tags = { Name = "${var.project_name}-nat" }
}

# --- Route tables ---------------------------------------------------------------
# A route table says "traffic going to <destination> should go via <target>".

# Public: internet traffic -> Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.project_name}-public-rt" }
}

# Private app: internet traffic -> NAT Gateway (outbound only)
resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = { Name = "${var.project_name}-private-app-rt" }
}

# Private DB: deliberately NO internet route. Only the automatic "local" route
# (VPC CIDR -> local) exists, so the database can talk to other VPC resources only.
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.project_name}-private-db-rt" }
}

# --- Associations: attach each subnet to its route table ------------------------
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_app" {
  count = length(aws_subnet.private_app)

  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app.id
}

resource "aws_route_table_association" "private_db" {
  count = length(aws_subnet.private_db)

  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db.id
}
