
data "aws_ami" "amazon-latest" {
    most_recent = true

    filter {
        name = "owner-alias"
        values = [ "amazon" ]
    }

    filter {
        name = "name"
        values = [ "amzn2-ami-*" ]
    }

    filter {
        name = "virtualization-type"
        values = [ "hvm" ]
    }
}


resource "aws_instance" "bastion" {
    ami                         = "${data.aws_ami.amazon-latest.id}"
    associate_public_ip_address = true
    iam_instance_profile        = "${aws_iam_instance_profile.bastion.id}"
    instance_type               = "t2.micro"
    key_name                    = "gfdfbggbf-24032403242"   # fake value
    vpc_security_group_ids      = [ "${aws_security_group.bastion.id}" ]
    subnet_id                   = "${aws_subnet.bastion.id}"

    tags = {
        "Name" = "bastion"
    }
}