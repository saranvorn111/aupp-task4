# main.tf is just a convention, not a requirement. 
# Terraform merges all .tf files in the directory into a single 
# configuration before planning and applying.

# EC2 Instance
resource "aws_instance" "webserver1" {
  ami                    = "ami-0ec10929233384c7f"
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ec2_key.key_name

  vpc_security_group_ids = [
    aws_security_group.terraform-web-sg.id
  ]

  user_data = file("${path.module}/userdata.sh")

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name = "Terraform-EC2"
  }

}
resource "aws_security_group" "terraform-web-sg" {

  name = "terraform-web-sg-01"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Terraform-Web-SG"
  }

 
}

resource "tls_private_key" "ec2_key"{
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "ec2_key" {
  key_name = "Terraform-Web-SG"
  public_key = tls_private_key.ec2_key.public_key_openssh
 }