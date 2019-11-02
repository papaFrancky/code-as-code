# PUBLIC SUBNET
# -------------

data "aws_availability_zones" "all" {}

resource "aws_subnet" "public" {
    count                   = "${length(data.aws_availability_zones.all.names)}"
    vpc_id                  = "${aws_vpc.demo.id}"
    cidr_block              = "${cidrsubnet(var.vpc_cidr, 8, 101 + count.index)}"
    map_public_ip_on_launch = true
    
    tags = {
        "Name" = "${var.vpc_name}-public-${element(data.aws_availability_zones.all.names, count.index)}"
    }
}



# INTERNET GATEWAY
# ----------------

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.demo.id}"

  tags = {
        "Name" = "${var.vpc_name}-internet-gateway"
    }
}

# PUBLIC ROUTE TABLE
# ------------------

resource "aws_route_table" "public" {
    vpc_id  = "${aws_vpc.demo.id}"
 
    tags = {
        "Name" = "${var.vpc_name}-public"
    }
}

resource "aws_route" "igw" {
    route_table_id          = "${aws_route_table.public.id}"
    destination_cidr_block  = "0.0.0.0/0"
    gateway_id              = "${aws_internet_gateway.igw.id}"
}

resource "aws_route_table_association" "public" {
    count           = "${length(data.aws_availability_zones.all.names)}"
    subnet_id       = "${element(aws_subnet.public.*.id, count.index)}"
    route_table_id  = "${aws_route_table.public.id}"
}
