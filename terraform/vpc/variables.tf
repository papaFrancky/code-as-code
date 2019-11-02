# INPUT VARIABLES
# ---

variable "aws_region" {
    description = "AWS region"
    type        = "string"
    default     = "eu-west-3"
}

variable "vpc_name" {
    description = "VPC name"
    type        = "string"
    default     = "demo"
}

variable "vpc_cidr" {
    description = "VPC cidr block"
    type        = "string"
    default     = "10.0.0.0/16"
}

