# Security group for the public Application Load Balancer
resource "aws_security_group" "alb" {
  name        = "devops-assessment-alb-sg"
  description = "Security group for the public ALB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "devops-assessment-alb-sg"
  }
}

# Allow HTTP traffic for redirect and temporary testing
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  description = "Allow HTTP access"
}

# Allow HTTPS traffic from the internet
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  description = "Allow HTTPS access"
}

# Security group for ECS Fargate tasks
resource "aws_security_group" "ecs" {
  name        = "devops-assessment-ecs-sg"
  description = "Security group for private ECS tasks"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "devops-assessment-ecs-sg"
  }
}

# Only the ALB can reach ECS on application port 8080
resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id = aws_security_group.ecs.id

  referenced_security_group_id = aws_security_group.alb.id

  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"

  description = "Allow application traffic from ALB"
}

# Allow ALB to communicate with ECS tasks
resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id = aws_security_group.alb.id

  referenced_security_group_id = aws_security_group.ecs.id

  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"

  description = "Allow ALB traffic to ECS"
}

# Allow ECS tasks to access ECR, CloudWatch and external services
resource "aws_vpc_security_group_egress_rule" "ecs_https" {
  security_group_id = aws_security_group.ecs.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  description = "Allow outbound HTTPS through NAT"
}

# Allow DNS queries to the VPC resolver
resource "aws_vpc_security_group_egress_rule" "ecs_dns_udp" {
  security_group_id = aws_security_group.ecs.id

  cidr_ipv4   = "10.0.0.0/16"
  from_port   = 53
  to_port     = 53
  ip_protocol = "udp"

  description = "Allow outbound DNS over UDP"
}

resource "aws_vpc_security_group_egress_rule" "ecs_dns_tcp" {
  security_group_id = aws_security_group.ecs.id

  cidr_ipv4   = "10.0.0.0/16"
  from_port   = 53
  to_port     = 53
  ip_protocol = "tcp"

  description = "Allow outbound DNS over TCP"
}
