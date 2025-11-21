CF SRE Technical Challenge – Comfort Benton

This repository contains my approach to the CF SRE Technical Challenge. The goal was to design and deploy a multi-tier, highly available web application environment in AWS using Terraform. The architecture includes a VPC, public and private subnets across two Availability Zones, an Internet Gateway, an Application Load Balancer, an Auto Scaling Group of Apache web servers, a backend subnet, and a dedicated management instance for secure administrative access.

I built the infrastructure using Terraform and tested the configuration locally using LocalStack and Docker.

1. Challenge Requirements (My Interpretation)

Based on the instructions provided, the solution needed to include:

One VPC with CIDR 10.1.0.0/16

Three subnetted groups spread evenly across two Availability Zones

Proper network segmentation

Public management access

Private application subnets

Backend subnet

EC2 running Apache in an Auto Scaling Group

Application Load Balancer routing traffic to ASG hosts

Management EC2 instance for SSH access

Security groups enforcing least privilege

Terraform modules or structured configurations

Architecture diagram

README including commentary, design reasoning, and operational improvements

I chose to build four subnets for the three groups instead of three to avoid combining application and backend workloads, and to satisfy AWS design principles that subnets do not span Availability Zones.

2. Architecture Decisions

Before writing any code, I created the architecture diagram. Working through a few versions helped me clearly define:

Each subnet’s purpose

How to separate public vs private routing

The path of user traffic

How the admin SSH path should work

Where the ASG should span

How the ALB fits into the design

Which components belong in AZ1 vs AZ2

Final Architecture Summary
VPC

CIDR: 10.1.0.0/16

Attached Internet Gateway (IGW)

Availability Zones

AZ1

Application Subnet A (private)

Management Subnet (public)

AZ2

Application Subnet B (private)

Backend Subnet (private)

Public Routing

Dedicated public route table for the management subnet

Contains:

0.0.0.0/0 → Internet Gateway

This enables secure admin access from the Internet into the Management EC2 instance.

Private Routing

Application A, Application B, and Backend subnets are associated with a private route table

No direct route to the Internet

This keeps the application and backend layers isolated

Traffic Flow

Users
Users → Internet → ALB → Application EC2s

Admin (restricted)
Admin → Internet → Internet Gateway → Public Route Table → Management EC2 → Application EC2

Security Groups

ALB-SG: allows HTTP/HTTPS from anywhere

APP-SG: allows HTTP/HTTPS from ALB and SSH only from Management

MGMT-SG: allows SSH only from my admin IP

This structure provides clear separation between public entry points, private workloads, and administrative access.

3. Building the Terraform Configuration

I created a project directory and organized Terraform code into multiple files:

providers.tf

Configured AWS provider to point to LocalStack

Allowed switching between local testing and real AWS

variables.tf

CIDRs

AMIs

Instance types

Boolean toggles, including:

create_ec2_instances

create_alb_resources

enable_https

network.tf

VPC

Internet Gateway

Public route table and association with the management subnet

Private route table and associations for private subnets

Four subnets

Security groups

compute.tf

Launch template for Apache web servers

Auto Scaling Group

Management EC2 (optional for LocalStack)

alb.tf

Application Load Balancer

Target Group

HTTP listener

Optional HTTPS listener (ACM certificate)

Conditional creation for LocalStack

outputs.tf

Helpful resource IDs

ALB DNS name (if enabled)

Breaking the project into these layers matched how I built and validated the architecture.

4. Local Testing With Docker and LocalStack

Before deploying anything, I installed:

Docker Desktop

LocalStack

Terraform CLI

I ran:

terraform init
terraform plan
terraform apply


LocalStack confirmed successful creation of the network layer:

1 VPC

Internet Gateway attached

Public route table sending 0.0.0.0/0 to the IGW

4 subnets

Route table associations

Security groups

EC2 Note for LocalStack

LocalStack does not fully emulate EC2, Auto Scaling, or ALB lifecycle behavior. Because of that, I set:

create_ec2_instances = false
create_alb_resources = false
enable_https         = false


This allowed me to validate the network, routing, subnets, and security groups without hitting unsupported APIs.

In a real AWS deployment, each of these would be set to true.

5. Traffic Flow Explanation (With IGW Clarification)
User Path

User sends an HTTP or HTTPS request

Request enters AWS through the Internet

Traffic is routed through the Internet Gateway

ALB receives the request

ALB forwards request to an application EC2 instance in either AZ

Apache responds back through the ALB to the user

Admin Path (Restricted SSH Access)

Admin connects from a trusted IP

Traffic enters through the Internet Gateway

Public route table forwards 0.0.0.0/0 to the management subnet

Admin authenticates to the Management EC2 instance

Admin can SSH into private application instances

No direct public access to application or backend subnets

The IGW and the dedicated public route table are the key elements that make remote administrative access possible.

6. What I Would Deploy in Real AWS

If this were deployed in live AWS:

Enable EC2 creation

Enable ALB creation

Attach a real ACM certificate for HTTPS

Add CloudWatch alarms (CPU, status checks, ALB health)

Add SSM Session Manager instead of relying purely on SSH

Enable ALB access logging

Configure autoscaling policies (CPU or request count)

Use a NAT Gateway if backend resources needed outbound access

7. Improvement Opportunities
Security

Force HTTPS by redirecting from HTTP

Add IAM roles for EC2

Use SSM Agent for secure access

Add NACLs for subnet-level protection

Availability

Add NAT Gateway for private outbound traffic

Add Route 53 health checks

Add DynamoDB or RDS for durability

Cost

Use t3.micro for modern burstable compute

Disable ALB in dev environments

Scheduled scaling for the ASG

Operations

CloudWatch Logs for ALB and EC2

Backup strategy for backend systems

Runbooks for scaling events and recovery

8. References & Independent Research Notes

During this challenge, I relied on publicly available AWS documentation and general cloud architecture resources to validate my understanding of best practices. These references were used strictly for clarification of concepts and to confirm that my design aligned with standard AWS architectural patterns.

Key reference areas included:

AWS VPC, Subnets, and Internet Gateway documentation

AWS Application Load Balancer and Auto Scaling Group guides

AWS Security Group and routing behavior

AWS Well-Architected Framework (networking and reliability sections)

General AWS architecture diagrams publicly available for visual comparison

Closing Summary

This challenge allowed me to design and build a clean, well-structured environment using Terraform. Starting with the architecture diagram allowed me to clearly define each part of the environment before building anything in code. I organized the Terraform project into modular layers, validated the network stack through LocalStack, and added configuration toggles to support both local testing and real AWS deployments.

The result is a deployable infrastructure-as-code solution that demonstrates:

Clear architecture thinking

Separation of public and private workloads

Proper use of an Internet Gateway and routing

Secure administrative access

Multi-AZ application design

Terraform best practices

I have included the architecture diagram, Terraform configuration, and detailed notes in this repository.
