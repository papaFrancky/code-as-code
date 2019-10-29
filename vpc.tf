
# GLOBAL VARIABLES
# ----------------
variable "environment" {
    description = "Environment name"
    type        = "string"
    default     = "demo"
}

variable "region" {
    description = "AWS region"
    type        = "string"
}

variable "availability_zones" {
    description = "Availability zones in the AWS region"
    type        = "list"
}

variable "bastion_instance_type" {
    description = "EC2 instance type for the bastion"
    type        = "string"
}

variable "cidr_block" {
    description = "VPC cidr block"
    type        = "string"
}



# INPUT VARIABLES
# ---------------

region                = "eu-west-3"
availability_zones    = ["eu-west-3a","eu-west-3b","eu-west-3c"]
bastion_instance_type = "t2.micro"
cidr_block            = "10.0.0.0/16"



# SUBNETS & ZONES
# ---------------
resource "aws_subnet" "public" {
    count                   = "${length(var.availability_zones)}"
    vpc_id                  = "${aws_vpc.main.id}"
    cidr_block              = "${cidrsubnet(var.cidr_block, 8, 101 + count.index)}"
    map_public_ip_on_launch = true
    
    tags = {
        "Name" = "public-${element(var.availability_zones, count.index)}"
    }
}

resource "aws_subnet" "private" {
    count                   = "${length(var.availability_zones)}"
    vpc_id                  = "${aws_vpc.main.id}"
    cidr_block              = "${cidrsubnet(var.cidr_block, 8, 201 + count.index )}"
    map_public_ip_on_launch = true
    
    tags = {
        "Name" = "private-${element(var.availability_zones, count.index)}"
    }
}



# NAT GATEWAYS
# ------------
resource "aws_nat_gateway" "main" {
    count           = "${length(var.availability_zones)}"
    subnet_id       = "${element(aws_subnet.public.*.id, count.index)}"
    allocation_id   = "${element(aws_eip.nat.*.id, count.index)}"

    tags = {
        "Name" = "nat-${element(var.availability_zones, count.index)}"
    }
}



# ROUTE TABLES
# ------------

resource "aws_route_table" "public" {
    vpc_id  = "${aws_vpc.main.id}"
 
    tags = {
        "Name" = "${var.environment}-public"
    }
}

resource "aws_route" "igw" {
    route_table_id          = "${aws_route_table.public.id}"
    destination_cidr_block  = "0.0.0.0/0"
    gateway_id              = "${aws_internet_gateway.main.id}"
}

resource "aws_route_table_association" "public" {
    count           = "${length(var.availability_zones)}"
    subnet_id       = "${element(aws_subnet.public.*.id, count.index)}"
    route_table_id  = "${aws_route_table.public.id}"
}


resource "aws_route_table" "private" {
    count   = "${length(var.availability_zones)}"
    vpc_id  = "${aws_vpc.main.id}"
 
    tags = {
        "Name" = "${var.environment}-private-${element(var.availability_zones, count.index)}"
    }
}

resource "aws_route" "nat" {
    count                   = "${length(var.availability_zones)}"
    route_table_id          = "${element(aws_route_table.private.*.id, count.index}"
    destination_cidr_block  = "0.0.0.0/0"
    nat_gateway_id          = "${element(aws_nat_gateway.main.*.id, count.index)}"
}

resource "aws_route_table_association" "private" {
    count           = "${length(var.availability_zones)}"
    subnet_id       = "${element(aws_subnet.private.*.id, count.index)}"
    route_table_id  = "${element(aws_route_table.private.*.id, count.index)}"
}



# OUTPUT VARIABLES
# ----------------

output "vpc_id" {
    value = "${aws_vpc.main.id}"
}

output "public_subnets_ids" {
    value = "${aws_subnet.public.*.id}"
}

output "public_cidrs" {
    value = "${aws_subnet.public.*.cidr_block}"
}

output "private_subnet_ids" {
    value = "${aws_subnet.private.*.id}"
}

output "private_cidrs" {
    value = "${aws_subnet.private.*.cidr_block}"
}

