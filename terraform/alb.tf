################################################################################
# APPLICATION LOAD BALANCER AND TARGET GROUP
################################################################################

# Application Load Balancer (internet-facing)
resource "aws_lb" "app_alb" {
  count = var.create_alb_resources ? 1 : 0

  name               = "app-alb"
  load_balancer_type = "application"
  internal           = false

  security_groups = [aws_security_group.alb_sg.id]

  # One subnet in each AZ to make the ALB multi-AZ
  subnets = [
    aws_subnet.app_a.id,
    aws_subnet.app_b.id,
  ]

  tags = {
    Name = "app-alb"
  }
}

# Target group for application instances
resource "aws_lb_target_group" "app_tg" {
  count = var.create_alb_resources ? 1 : 0

  name        = "app-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/"
    matcher             = "200"
    interval            = 30
    unhealthy_threshold = 2
    healthy_threshold   = 2
    timeout             = 5
  }

  tags = {
    Name = "app-tg"
  }
}

################################################################################
# LISTENERS
################################################################################

# HTTP listener on port 80
resource "aws_lb_listener" "http" {
  count = var.create_alb_resources ? 1 : 0

  load_balancer_arn = aws_lb.app_alb[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg[0].arn
  }
}

################################################################################
# OPTIONAL HTTPS SUPPORT (DISABLED FOR LOCALSTACK)
################################################################################

# ACM certificate for HTTPS (only created when enable_https = true AND create_alb_resources = true)
resource "aws_acm_certificate" "app_cert" {
  count = var.enable_https && var.create_alb_resources ? 1 : 0

  domain_name       = "example.com"     # placeholder domain for this challenge
  validation_method = "DNS"

  tags = {
    Name = "app-cert"
  }
}

# HTTPS listener on port 443 (only created when enable_https = true AND create_alb_resources = true)
resource "aws_lb_listener" "https" {
  count = var.enable_https && var.create_alb_resources ? 1 : 0

  load_balancer_arn = aws_lb.app_alb[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  certificate_arn = aws_acm_certificate.app_cert[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg[0].arn
  }
}

################################################################################
# OUTPUT
################################################################################

# Use try() so this output is safe even when no ALB is created (LocalStack mode)
output "alb_dns_name" {
  value       = try(aws_lb.app_alb[0].dns_name, "")
  description = "DNS name of the Application Load Balancer"
}
