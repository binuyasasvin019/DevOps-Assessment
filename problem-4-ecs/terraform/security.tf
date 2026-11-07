
# ============================================================
# CloudFront Managed Prefix List
# ============================================================

# AWS-managed IP ranges used by CloudFront to connect to origins.
# AWS maintains these ranges automatically.
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}


# ============================================================
# Application Load Balancer Security Group
# ============================================================

resource "aws_security_group" "alb" {
  name        = "devops-assessment-alb-sg"
  description = "Security group for the public ALB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "devops-assessment-alb-sg"
  }
}

# Allow HTTP access only from CloudFront origin-facing servers.
# HTTPS is terminated at CloudFront, so the ALB uses HTTP port 80.
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id

  prefix_list_id = data.aws_ec2_managed_prefix_list.cloudfront.id

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  description = "Allow HTTP only from CloudFront origins"
}


# ============================================================
# ECS Fargate Security Group
# ============================================================

resource "aws_security_group" "ecs" {
  name        = "devops-assessment-ecs-sg"
  description = "Security group for private ECS Fargate tasks"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "devops-assessment-ecs-sg"
  }
}

# Allow application traffic only from the ALB security group.
resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id = aws_security_group.ecs.id

  referenced_security_group_id = aws_security_group.alb.id

  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"

  description = "Allow application traffic from ALB on port 8080"
}


# ============================================================
# ALB Outbound Rules
# ============================================================

# Allow ALB to forward traffic and perform health checks
# against ECS Fargate tasks on port 8080.
resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id = aws_security_group.alb.id

  referenced_security_group_id = aws_security_group.ecs.id

  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"

  description = "Allow ALB traffic to ECS on port 8080"
}


# ============================================================
# ECS Outbound Rules
# ============================================================

# Allow ECS tasks to access AWS services such as ECR and
# CloudWatch Logs through the NAT Gateway.
resource "aws_vpc_security_group_egress_rule" "ecs_https" {
  security_group_id = aws_security_group.ecs.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  description = "Allow outbound HTTPS through NAT Gateway"
}

# Allow DNS queries over UDP.
resource "aws_vpc_security_group_egress_rule" "ecs_dns_udp" {
  security_group_id = aws_security_group.ecs.id

  cidr_ipv4   = "10.0.0.0/16"
  from_port   = 53
  to_port     = 53
  ip_protocol = "udp"

  description = "Allow outbound DNS over UDP"
}

# Allow DNS queries over TCP.
resource "aws_vpc_security_group_egress_rule" "ecs_dns_tcp" {
  security_group_id = aws_security_group.ecs.id

  cidr_ipv4   = "10.0.0.0/16"
  from_port   = 53
  to_port     = 53
  ip_protocol = "tcp"

  description = "Allow outbound DNS over TCP"
}
