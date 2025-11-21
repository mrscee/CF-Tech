# Management EC2 instance in the public management subnet (AZ1)

resource "aws_instance" "mgmt" {
  count = var.create_ec2_instances ? 1 : 0

  ami                    = "ami-12345678"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.mgmt.id
  vpc_security_group_ids = [aws_security_group.mgmt_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "management-ec2"
    Role = "management"
  }
}
# Launch template for application instances in the ASG
resource "aws_launch_template" "app" {
  name_prefix   = "app-lt-"
  image_id      = "ami-12345678"        # placeholder AMI; in real AWS use a proper Amazon Linux 2 AMI
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = filebase64("${path.module}/scripts/userdata-web.sh")

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "app-asg-instance"
      Role = "web"
    }
  }

  tags = {
    Name = "app-launch-template"
  }
}
# Auto Scaling Group for application instances
resource "aws_autoscaling_group" "app_asg" {
  count = var.create_ec2_instances ? 1 : 0

  name                      = "app-asg"
  min_size                  = 2
  max_size                  = 6
  desired_capacity          = 2
  health_check_type         = "EC2"
  health_check_grace_period = 60

  vpc_zone_identifier = [
    aws_subnet.app_a.id,
    aws_subnet.app_b.id,
  ]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # Attach to target group only when ALB resources are enabled
    target_group_arns = var.create_alb_resources ? aws_lb_target_group.app_tg[*].arn : []

  tag {
    key                 = "Name"
    value               = "app-asg-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}


