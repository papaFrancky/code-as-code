# OUTPUT VARIABLES

output "aws_region" {
  value = "${var.aws_region}"
}

output "demo_vpc_id" {
  value = "${aws_vpc.demo.id}"
}

output "public_subnets_ids" {
    value = "${aws_subnet.public.*.id}"
}

output "public_subnets_names" {
  value = "${aws_subnet.public.*.tags.Name}"
}

output "public_cidrs" {
    value = "${aws_subnet.public.*.cidr_block}"
}

