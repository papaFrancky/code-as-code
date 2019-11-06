# AMI (Amazon Machine Image)
# --------------------------

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