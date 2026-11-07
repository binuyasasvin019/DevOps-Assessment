
# Application Load Balancer hostname
output "alb_dns_name" {
  description = "Public DNS hostname of the Application Load Balancer"
  value       = aws_lb.app.dns_name
}

# Application URL for initial HTTP testing
output "application_url" {
  description = "HTTP URL for testing the deployed application"
  value       = "http://${aws_lb.app.dns_name}"
}

# ECR repository URL
output "ecr_repository_url" {
  description = "Private ECR repository URL for container images"
  value       = aws_ecr_repository.app.repository_url
}

# ECS cluster name
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.app.name
}

# ECS service name
output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app.name
}

# VPC ID
output "vpc_id" {
  description = "ID of the application VPC"
  value       = aws_vpc.main.id
}

# WAF Web ACL ARN
output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.app.arn
}
output "cloudfront_domain_name" {
  description = "CloudFront distribution DNS name"
  value       = aws_cloudfront_distribution.app.domain_name
}

output "cloudfront_https_url" {
  description = "Public HTTPS URL for the ECS application"
  value       = "https://${aws_cloudfront_distribution.app.domain_name}"
}