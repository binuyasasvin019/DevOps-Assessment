# Senior DevOps Engineer — Take-Home Assessment

This repository contains my solutions to the Senior DevOps Engineer Take-Home Assessment, covering AWS security, infrastructure automation, cloud architecture, containerisation, Infrastructure as Code (IaC), and CI/CD.

The four mandatory problems are organised into separate directories, each containing its own documentation, implementation details, and supporting code or evidence.

## Assessment Overview

| Problem | Description | Documentation |
|---|---|---|
| **Problem 1 — IAM Policies** | Least-privilege AWS IAM policies covering S3 access, administrative permissions with IAM self-service, and per-user Secrets Manager access. | [Problem 1](problem-1-iam/) |
| **Problem 2 — EC2 Bootstrap** | Idempotent Ubuntu 24.04 bootstrap automation for Java, unattended security updates, and Datadog Agent installation using AWS Systems Manager Parameter Store. | [Problem 2](problem-2-ec2-bootstrap/) |
| **Problem 3 — Architecture** | AWS architecture solutions for static website hosting, scheduled data processing, and cross-region S3 transfers, including design decisions and cost considerations. | [Problem 3](problem-3-architecture/) |
| **Problem 4 — ECS & CI/CD** | Containerised application deployed to Amazon ECS using Terraform, Docker, Nginx, GitHub Actions, and ECR, with deployment health checks, automatic rollback, and staging-to-production promotion. | [Problem 4](problem-4-ecs/) |

Problems 5 and 6 are optional stretch exercises and are not included in this submission.

## Live Application — Problem 4

A sample containerised application is deployed on AWS ECS Fargate and exposed through Amazon CloudFront over HTTPS.

| Endpoint | URL | Purpose |
|---|---|---|
| Application | [Home Page](https://d312yhfal6qb8g.cloudfront.net/) | Public application entry point |
| Readiness | [Health Ready](https://d312yhfal6qb8g.cloudfront.net/health/ready) | Confirms the application is ready to serve traffic |
| Liveness | [Health Live](https://d312yhfal6qb8g.cloudfront.net/health/live) | Confirms the application process is responding |

## Problem 4 — Implementation Highlights

**Infrastructure**
- AWS ECS Fargate and Amazon ECR
- VPC with public and private subnets
- Application Load Balancer and target group health checks
- CloudFront HTTPS delivery and AWS WAF
- CloudWatch Logs and IAM roles
- Terraform with S3 remote state and native S3 state locking

**CI/CD and Security**
- GitHub Actions with AWS OIDC authentication
- Container image builds, vulnerability scanning, and ECR publishing
- Git commit SHA tagging and immutable image digests
- Automated ECS deployment and health verification
- Separate staging and production ECS services
- GitHub environment approval for production promotion
- ECS deployment circuit breaker with automatic rollback

## Deployment Verification

The ECS deployment, rollback, and staging-to-production promotion workflows were successfully tested.

| Test | Result |
|---|---|
| Staging ECS deployment | Passed |
| Staging ALB target health verification | Passed |
| Production ECS deployment | Passed |
| Immutable image promotion | Verified |
| Automatic rollback test | Verified |
| Production deployment evidence | Captured |

**Evidence**
- [Successful staging-to-production promotion](https://github.com/binuyasasvin019/DevOps-Assessment/actions/runs/42477999539)
- [Automatic rollback verification](https://github.com/binuyasasvin019/DevOps-Assessment/actions/runs/42460763961)
- [GitHub Actions workflows](.github/workflows/)

## Technologies

AWS · Terraform · Docker · Nginx · Python · Bash · GitHub Actions · Amazon ECS · Amazon ECR · IAM · CloudFront · AWS WAF · CloudWatch

## Documentation

Detailed solutions, configuration files, design explanations, deployment instructions, architecture diagrams, and available screenshots are maintained within the respective problem directories.

The implementation emphasises least-privilege security, automation, reproducibility, reliability, and deployment recovery.
