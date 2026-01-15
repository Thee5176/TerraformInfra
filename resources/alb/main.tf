# ALB Security Group
resource "aws_security_group" "alb_sg" {
    description = "Allow HTTP and HTTPS inbound traffic"
    vpc_id      = var.vpc_id
    
    ingress {
        description      = "HTTP from anywhere"
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
    
    ingress {
        description      = "HTTPS from anywhere"
        from_port        = 443
        to_port          = 443
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    egress {
        description      = "All outbound traffic"
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    tags = {
        Name        = "${var.project_name}_alb_sg"
        Environment = var.environment_name
    }
}

# ALB
resource "aws_lb" "backend_alb"{
    name = var.project_name
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.alb_sg.id]
    subnets = var.alb_subnet_ids # Internet-facing subnets
    enable_deletion_protection = false
    ip_address_type = "dualstack"
    tags = {
        Name = "${var.project_name}_backend_alb"
        Environment = var.environment_name
    }
}

# ALB Listener
resource "aws_lb_listener" "alb_listener_https" {
  load_balancer_arn = aws_lb.backend_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn
  ssl_policy        = var.ssl_policy

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_target_group.arn
  }

  tags = {
    Name        = "${var.project_name}_alb_listener"
    Environment = var.environment_name
  }
}

# HTTP to HTTPS redirect listener
resource "aws_lb_listener" "alb_listener_http_redirect" {
  load_balancer_arn = aws_lb.backend_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = {
    Name        = "${var.project_name}_alb_listener_redirect"
    Environment = var.environment_name
  }
}

# Define Backend Target Group
resource "aws_lb_target_group" "backend_target_group" {
  # name        = "${var.project_name}-lb-tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  tags = {
        Name = "${var.project_name}_backend_target_group"
        Environment = var.environment_name
    }
}

# Register Backend Target
resource "aws_lb_target_group_attachment" "app_instance" {
  target_group_arn = aws_lb_target_group.backend_target_group.arn
  target_id        = var.ec2_instance_id
  port             = 80
}

# Target group for command API (instance port 8181)
resource "aws_lb_target_group" "command_api_tg" {
  target_type = "instance"
  port        = 8181
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 300
    matcher             = "200-399"
  }
  tags = {
    Name        = "${var.project_name}_command_api_tg"
    Environment = var.environment_name
  }
}

resource "aws_lb_target_group_attachment" "command_instance" {
  target_group_arn = aws_lb_target_group.command_api_tg.arn
  target_id        = var.ec2_instance_id
  port             = 8181
}

# Target group for query API (instance port 8182)
resource "aws_lb_target_group" "query_api_tg" {
  target_type = "instance"
  port        = 8182
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 300
    matcher             = "200-399"
  }
  tags = {
    Name        = "${var.project_name}_query_api_tg"
    Environment = var.environment_name
  }
}

resource "aws_lb_target_group_attachment" "query_instance" {
  target_group_arn = aws_lb_target_group.query_api_tg.arn
  target_id        = var.ec2_instance_id
  port             = 8182
}

# Listener rule for command API paths
resource "aws_lb_listener_rule" "command_rule" {
  listener_arn = aws_lb_listener.alb_listener_https.arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.command_api_tg.arn
  }
  condition {
    path_pattern { values = ["/api/command/*", "/command/*"] }
  }
}

# Listener rule for query API paths
resource "aws_lb_listener_rule" "query_rule" {
  listener_arn = aws_lb_listener.alb_listener_https.arn
  priority     = 11
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.query_api_tg.arn
  }
  condition {
    path_pattern { values = ["/api/query/*", "/query/*"] }
  }
}

resource "aws_security_group_rule" "allow_alb_to_command_service" {
  description              = "Allow ALB to reach EC2 on HTTP port ${var.command_service_port}"
  type                     = "ingress"
  to_port                  = var.command_service_port
  from_port                = var.command_service_port
  protocol                 = "tcp"
  security_group_id        = var.web_sg_id
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "allow_alb_to_query_service" {
  description              = "Allow ALB to reach EC2 on HTTP port ${var.query_service_port}"
  type                     = "ingress"
  to_port                  = var.query_service_port
  from_port                = var.query_service_port
  protocol                 = "tcp"
  security_group_id        = var.web_sg_id
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "allow_alb_to_ec2" {
  description              = "Allow ALB to reach EC2 on HTTP"
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = var.web_sg_id
  source_security_group_id = aws_security_group.alb_sg.id
}