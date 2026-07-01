variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "aws_region" {
  type = string
}
variable "key_name" {
  description = "Existing AWS EC2 Key Pair"
  type        = string
  default     = "mykeypair"
}