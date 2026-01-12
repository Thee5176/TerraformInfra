##------------------------RDS Instance---------------------------

# DB Subnet Group : 2 or more subnets in different AZ
resource "aws_db_subnet_group" "db_sg_group" {
  subnet_ids = var.db_subnet_ids

  tags = {
    Name    = "${var.project_name}_db_sg_group"
    Environment = var.environment_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Add depends_on to ensure VPC exists before creating subnet
// Subnets are supplied by the root vpc module via variable `db_subnet_ids`
# DB_parameter
resource "aws_db_parameter_group" "db_param_group" {
  description = "Parameter group for web database"
  family      = "postgres17"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  tags = {
    Name    = "${var.project_name}_db_param_group"
    Environment = var.environment_name
  }
}

# RDS
resource "aws_db_instance" "web_db" {
  instance_class         = "db.t3.micro"
  engine                 = "postgres"
  engine_version         = "17.4"
  allocated_storage      = 5
  username               = var.db_username
  password               = var.db_password
  db_name                = var.db_schema
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_sg_group.name
  parameter_group_name   = aws_db_parameter_group.db_param_group.name
  publicly_accessible    = true
  skip_final_snapshot    = true

  tags = {
    Name = "${var.project_name}_db_instance"
    Environment = var.environment_name
  }
}

# DB Security Group
resource "aws_security_group" "db_sg" {
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description      = "Allow DB access from anywhere"
    from_port        = 5432
    to_port          = 5432
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

  tags = {
    Name    = "${var.project_name}_db_sg"
    Environment = var.environment_name
  }
}

# # Private Route Table (No Table Associate)
# resource "aws_route_table" "private_route" {
#   vpc_id = aws_vpc.main_vpc.id

#   tags = {
#     Name    = var.project_name"
#     Environment = var.environment_name
#   }
# }

# Ingress Rules
resource "aws_security_group_rule" "ec2_to_rds_ingress" {
  type                     = "ingress"
  description              = "Allow DB access from anywhere web servers"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_sg.id
  source_security_group_id = var.web_sg_id
} 