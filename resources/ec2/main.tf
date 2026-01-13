# Data source to fetch the correct Ubuntu 22.04 LTS ARM64 AMI for the current region
data "aws_ami" "ubuntu_arm64" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

##------------------------EC2 Instance---------------------------
# EC2
resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.ubuntu_arm64.id # Ubuntu 22.04 LTS ARM64
  instance_type               = var.ec2_instance_type
  key_name                    = aws_key_pair.deployment_key.key_name
  subnet_id                   = var.web_subnet_id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_profile.name

  user_data_base64 = base64encode(<<-EOF
    #!/bin/bash
    set -e  # Exit on any error
    
    exec > /tmp/user_data.log 2>&1  # Capture all output to log file
    echo "=== Starting user_data script ===" 
    
    echo "=== Updating system ===" 
    apt-get update -y
    apt-get install -y git
    
    echo "=== Attempting to install SSM Agent ===" 
    apt-get install -y amazon-ssm-agent || echo "SSM Agent not available in this region/architecture, skipping"
    
    echo "=== Starting SSM Agent if available ===" 
    systemctl start amazon-ssm-agent 2>/dev/null || echo "SSM Agent service not available"
    systemctl enable amazon-ssm-agent 2>/dev/null || echo "SSM Agent service not available"
    
    echo "=== Installing Docker ===" 
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker ubuntu

    echo "=== Installing Docker Compose ===" 
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

    echo "=== Starting Docker service ===" 
    systemctl start docker
    systemctl enable docker

    echo "=== Verifying installations ===" 
    git --version
    docker --version
    docker-compose --version

    echo "=== Cloning repository ===" 
    cd /home/ubuntu
    sudo -u ubuntu git clone --recurse-submodules -j3 https://github.com/Thee5176/Accounting_CQRS_Project.git
    
    echo "=== User data script completed successfully ===" 
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

