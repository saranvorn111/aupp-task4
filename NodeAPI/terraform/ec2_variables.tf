resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  key_name   = "mykeypair"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "aws_instance" "web_server" {

  ami           = "ami-0ec10929233384c7f"
  instance_type = var.instance_type

  key_name = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [
    aws_security_group.web_sg.id
  ]

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name = "StaticWebsiteServer"
  }
}

resource "aws_security_group" "web_sg" {

  name_prefix = "web-sg-"
  description = "Security group for NodeJS"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
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
    Name = "web-sg"
  }
}