# VARIABLES
# ---------

variable "aws_region" {
    description = "AWS region"
    type        = "string"
    default     = "eu-west-3"
}
variable "http_port" {
    description = "HTTP port"
    type        = "string"
    default     = 80
}
