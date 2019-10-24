
# export AWS_ACCESS_KEY_ID="anaccesskey"
# export AWS_SECRET_ACCESS_KEY="asecretkey"
# export AWS_DEFAULT_REGION="us-west-2"

# Steps :
#  AMI                           : latest Amazon Linux 2 HVM 64 bit 
#  instance type                 : t2.micro
#  Network (VPC)                 : demo-infra-vpc
#  Subnet                        : demo-infra-pubaz1-10-0-101-0
#  Auto-assign public IP         : enable
#  IAM role                      : demo-infra-role-bastion
#  User-data                     : yes (see above)
#  Tags
#        env                     : code
#        subenv                  : infra
#        type                    : ec2-bastion
#        Name                    : code-infra-ec2-bastion
#  Security Group                : demo-infra-sg-bastion
#        Type               Protocol    Port Range    Source       Description
#        HTTP               TCP         80            0.0.0.0/0    HTTP from anywhere
#        SSH                TCP         22            0.0.0.0/0    SSH from anywhere
#        All ICMP - IPV4    All         N/A           0.0.0.0/0    All ICMP IPv4 from anywhere
#

# Provider AWS region Paris
provider "aws" {
  region = "eu-west-3"
}

variable "http_port" {
  description = "TCP port used by the web server"
  type        = "string"
  default     = 80
}


# Security group
resource "aws_security_group" "code-infra-sg-bastion" {
  name = "code-infra-sg-bastion"
  description = "security group applied to bastion"
  ingress {
    description = "HTTP from anywhere"
    protocol    = "tcp"
    from_port   = "${var.http_port}"
    to_port     = "${var.http_port}"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH from anywhere"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ICMP from anywhere"
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Most recent Amazon Linux AMI (virt. type: HVM)
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# Paire de clés SSH
resource "tls_private_key" "demo2-infra-key-bastion" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

variable "tag_env" {
  description = "tag: env"
  type        = "string"
  default     =" code"
}

variable "tag_subenv" {
  description = "tag: subenv"
  type        = "string"
  default     = "infra"
}

variable "tag_type" {
  description = "tag: type"
  type        = "string"
  default     = "ec2-bastion"  
}


resource "aws_instance" "bastion" {
  ami                         = "${data.aws_ami.amazon-linux-2.id}"
  instance_type               = "t2.micro"
  subnet_id                   = "${aws_subnet.demo-infra-pubaz1-10-0-101-0.id}"
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.demo-infra-role-bastion.id}"
  user_data                   = "{file("user-data.bash")}"
  tags {
    env    = "code"
    subenv = "infra"
    type   = "ec2-bastion"
    Name   = "${var.tag_env}-${var.tag_subenv}-${var.tag_type}"
  }
  vpc_security_group_ids      = ["${aws_security_group.code-infra-sg-bastion.id}"]
  key_name                    = "demo-infra-key-bastion"     #"${tls_private_key.demo2-infra-key-bastion.public_key_openssh}"
}


##########

# ref: https://medium.com/slalom-technology/how-to-optimize-network-infrastructure-code-in-terraform-fff16fada668

availability_zones = ["eu-west-1a","eu-west-1b","eu-west-1c"]

resource "aws_subnet" "public" {
  count                   = "${length(var.availability_zones)}"
  vpc_id                  = "${aws.vpc.main.id}"
  cidr_block              = "${cidrsubnet(var.cidr_block, 8, count.index)}"
  availability_zone       = "${element(var.availability_zones, count.index)}"
  map_public_ip_on_launch = true
}

tags = {
    "Name" = "Public subnet - ${element(var.availability_zones, count.index)}"
}