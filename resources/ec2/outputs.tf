
output "ec2_public_ip" {
	description = "IPv6 address of the web server"
	value       = length(aws_instance.web_server.ipv6_addresses) > 0 ? aws_instance.web_server.ipv6_addresses[0] : null
}

output "web_sg_id" {
	description = "Security Group id created for web server"
	value       = aws_security_group.web_sg.id
}

output "ec2_instance_id"{
	description = "Instance id of the web server"
	value       = aws_instance.web_server.id
}

output "ec2_ipv6_address" {
	description = "IPv6 address of the web server"
	value       = length(aws_instance.web_server.ipv6_addresses) > 0 ? aws_instance.web_server.ipv6_addresses[0] : null
}