
resource "aws_iam_role" "terraform-bastion" {
  name                  = "terraform-bastion"
  description           = "IAM role for the EC2 instance terraform-bastion"
  assume_role_policy    = "${file("files/ec2-trust.json")}"

  tags = {
      Name = "terraform-bastion"
  }
}


resource "aws_iam_instance_profile" "terraform-bastion" {
  name = "terraform-bastion"
  role = "${aws_iam_role.terraform-bastion.name}"
}


resource "aws_iam_role_policy" "terraform-ec2-describe-instances" {
  name      = "teraform-ec2-describe-instances"
  role      = "${aws_iam_role.terraform-bastion.id}"
  policy    = "${file("files/ec2-describe-instances.json")}"
}


resource "aws_iam_role_policy" "terraform-ec2-describe-tags" {
  name      = "terraform-ec2-describe-tags"
  role      = "${aws_iam_role.terraform-bastion.id}"
  policy    = "${file("files/ec2-describe-tags.json")}"
}


resource "aws_iam_role_policy" "terraform-ec2-access" {
  name      = "terraform-ec2-access"
  role      = "${aws_iam_role.terraform-bastion.id}"
  policy    = "${file("files/ec2-access.json")}"
}


resource "aws_iam_role_policy" "terraform-route53-upsert-records" {
  name      = "terraform-route53-upsert-records"
  role      = "${aws_iam_role.terraform-bastion.id}"
  policy    = "${file("files/route53-upsert-records.json")}"
}


resource "aws_iam_role_policy" "terraform-s3-access" {
  name      = "terraform-s3-access"
  role      = "${aws_iam_role.terraform-bastion.id}"
  policy    = "${file("files/s3-access.json")}"
}

