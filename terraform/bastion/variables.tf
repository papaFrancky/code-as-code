# VARIABLES
# ---------

variable "vpc_name" {
    description = "VPC name"
    type        = "string"
    default     = "demo"
}


variable "aws_region" {
    description = "AWS region"
    type        = "string"
    default     = "eu-west-3"
}


variable "instance_type" {
    description = "EC2 instance type"
    type        = string
    default     = "t2.micro"
}


variable "ssh_key" {
    description = "SSH key"
    type        = string
    default     = "bastion"
}


variable "http_port" {
    description = "HTTP port"
    type        = "string"
    default     = 80
}
