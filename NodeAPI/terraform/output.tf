output "instance_id" {
  value = aws_instance.webserver1.id
}

output "public_ip" {
  description = "Public IP of EC2 Instance"
  value       = aws_instance.webserver1.public_ip
}

output "private_ip" {
  description = "Private IP of EC2 Instance"
  value       = aws_instance.webserver1.private_ip
}

output "public_dns" {
  value = aws_instance.webserver1.public_dns
}