# SECURITY GROUP
# --------------


data aws_vpc demo {
  tags = {
    "Name" = var.vpc_name
  }
}


resource aws_security_group terraform-bastion {
  name          = "terraform-bastion"
  description   = "Security group applied to the bastion"
  vpc_id        = data.aws_vpc.demo.id

  ingress {
    description = "HTTP from anywhere"
    protocol    = "tcp"
    from_port   = var.http_port
    to_port     = var.http_port
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

   tags = {
      "Name" = "terraform-bastion"
  }
}
