variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default = "t2.micro" # If terraform.tfvars is missing it will take t2.micro
                       # otherwise it will take from terraform.tfvars
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default = "us-east-1"
}

variable "key_name" {
  description = "EC2 Key Pair Name"
  type        = string
  default = "my-key"
}