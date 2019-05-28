data "aws_availability_zones" "available" {}

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = var.name
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name = var.name
  }
}

resource "aws_route" "internet_gateway_egress" {
  route_table_id         = "${aws_vpc.vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.internet_gateway.id}"
}

resource "aws_subnet" "public" {
  count                   = "${var.az_count}"
  cidr_block              = "${cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index)}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id                  = "${aws_vpc.vpc.id}"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet ${data.aws_availability_zones.available.names[count.index]}"
  }
}

resource "aws_eip" "nat_gateway_ip" {
  count      = "${var.az_count}"
  vpc        = true
  depends_on = ["aws_internet_gateway.internet_gateway"]

  tags = {
    Name = "NAT Gateway ${data.aws_availability_zones.available.names[count.index]}"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  count         = "${var.az_count}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
  allocation_id = "${element(aws_eip.nat_gateway_ip.*.id, count.index)}"

  tags = {
    Name = "NAT Gateway ${data.aws_availability_zones.available.names[count.index]}"
  }
}

resource "aws_route_table" "private" {
  count  = "${var.az_count}"
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.nat_gateway.*.id, count.index)}"
  }

  tags = {
    Name = "Private Subnet Route Table ${data.aws_availability_zones.available.names[count.index]}"
  }
}

resource "aws_route_table_association" "private" {
  count          = "${var.az_count}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

resource "aws_subnet" "private" {
  count             = "${var.az_count}"
  cidr_block        = "${cidrsubnet(aws_vpc.vpc.cidr_block, 8, var.az_count + count.index)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id               = "${aws_vpc.vpc.id}"

  tags = {
    Name = "Private Subnet ${data.aws_availability_zones.available.names[count.index]}"
  }
}
