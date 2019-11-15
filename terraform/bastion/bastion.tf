
data "aws_ami" "amazon-latest" {
    most_recent = true
    owners      = [ "amazon" ]

    filter {
        name    = "name"
        values  = [ "amzn2-ami-*" ]
    }

    filter {
        name    = "virtualization-type"
        values  = [ "hvm" ]
    }
}


data "aws_subnet" "demo-public-eu-west-3a" {
    filter {
        name    = "tag:Name"
        values  = [ "demo-public-eu-west-3a" ]
    }
}


resource "aws_instance" "terraform-bastion" {
    ami                         = "${data.aws_ami.amazon-latest.id}"
    associate_public_ip_address = true
    iam_instance_profile        = "${aws_iam_instance_profile.terraform-bastion.id}"
    instance_type               = "${var.instance_type}"
    key_name                    = "${var.ssh_key}"
    vpc_security_group_ids      = [ "${aws_security_group.terraform-bastion.id}" ]
    subnet_id                   = "${data.aws_subnet.demo-public-eu-west-3a.id}"
    user_data                   = "${file("./files/user-data.bash")}"

    tags = {
        "Name" = "terraform-bastion"
    }
}