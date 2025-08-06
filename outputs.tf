output "frontend_public_ip" {
  description = "Public IP of the Frontend EC2 Instance"
  value       = aws_instance.frontend.public_ip
}

output "backend_private_ip" {
  description = "Private IP of the Backend EC2 Instance"
  value       = aws_instance.backend.private_ip
}

