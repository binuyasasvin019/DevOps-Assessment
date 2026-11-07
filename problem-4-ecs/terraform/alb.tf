# Internet-facing Application Load Balancer
resource "aws_lb" "app" {
  name               = "devops-assessment-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb.id]
  subnets         = aws_subnet.public[*].id

  tags = {
    Name = "devops-assessment-alb"
  }
}

# Target group for ECS Fargate tasks
resource "aws_lb_target_group" "app" {
  name        = "devops-assessment-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/health/ready"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "devops-assessment-tg"
  }
}

# HTTP listener for initial deployment
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
