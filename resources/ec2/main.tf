# EC2
resource "aws_instance" "web_server" {
  ami                         = var.ec2_ami_id
  instance_type               = var.ec2_instance_type
  key_name                    = aws_key_pair.deployment_key.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_profile.name
  subnet_id                   = var.web_subnet_id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  user_data_replace_on_change = true

  user_data_base64 = base64encode(<<-EOF
    #!/bin/bash
    set -e  # Exit on any error
    
    # Log everything to file for debugging
    exec > >(tee /var/log/user-data.log)
    exec 2>&1
    
    echo "=== Starting user-data script at $(date) ===" 
    
    echo "=== Updating system ===" 
    apt-get update -y
    apt-get install -y git curl
    
    echo "=== Installing Docker ===" 
    curl -fsSL https://get.docker.com | sh
    apt-get install -y docker-compose-plugin
    
    echo "=== Adding ubuntu user to docker group ===" 
    usermod -aG docker ubuntu
    
    echo "=== Enabling and starting Docker service ==="
    systemctl enable docker
    systemctl start docker
    systemctl status docker
    
    echo "=== Verifying installations ===" 
    git --version
    docker --version
    docker compose version
    
    echo "=== Cloning repository to /home/ubuntu ===" 
    cd /home/ubuntu
    sudo -u ubuntu git clone --recurse-submodules -j3 https://github.com/Thee5176/Accounting_CQRS_Project.git
    chown -R ubuntu:ubuntu /home/ubuntu/Accounting_CQRS_Project
    
    echo "=== User data script completed successfully at $(date) ===" 
    echo "=== Check logs at: /var/log/user-data.log ==="
    EOF
  )

  tags = {
    Name    = "${var.project_name}_ec2_instance"
    Environment = var.environment_name
  }
}

# EC2 Security Group : allow access in instance level
resource "aws_security_group" "web_sg" {
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = var.vpc_id
  ingress {
    description      = "SSH from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  ingress {
    description      = "Allow incoming data fetch to command service"
    from_port        = var.command_service_port
    to_port          = var.query_service_port
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# EC2 SSH Key
resource "aws_key_pair" "deployment_key" {
  key_name = "github_workflow_key"
  public_key = var.ec2_public_key

  tags = {
    Name    = "${var.project_name}_ec2_deployment_key"
    Environment = var.environment_name
  }
}

# IAM Role for EC2 to use SSM Session Manager
resource "aws_iam_role" "ec2_ssm_role" {
  name = "${var.project_name}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}_ec2_ssm_role"
    Environment = var.environment_name
  }
}

# Attach the AmazonSSMManagedInstanceCore policy
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile for the IAM Role
resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "${var.project_name}-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

