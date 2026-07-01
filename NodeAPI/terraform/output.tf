output "instance_id" {
  value = aws_instance.web_server.id
}

output "public_ip" {
  description = "Public IP of EC2 Instance"
  value       = aws_instance.web_server.public_ip
}


output "private_ip" {
  description = "Private IP of EC2 Instance"
  value       = aws_instance.web_server.private_ip
}

output "public_dns" {
  value = aws_instance.web_server.public_dns
}