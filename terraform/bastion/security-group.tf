# SECURITY GROUP
# --------------

resource "aws_security_group" "sg-bastion" {
  name = "sg-bastion"
  description = "Security group applied to the bastion"
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
