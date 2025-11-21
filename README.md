# CF SRE Technical Challenge – Comfort Benton

This repository contains my approach to the CF SRE Technical Challenge. The goal was to design and deploy a multi-tier, highly available web application environment in AWS using Terraform. The architecture includes a VPC, public and private subnets across two Availability Zones, an Internet Gateway, an Application Load Balancer, an Auto Scaling Group of Apache web servers, a backend subnet, and a dedicated management instance for secure administrative access.

I built the infrastructure using Terraform and tested the configuration locally using LocalStack and Docker.

---

## 1. Architecture Diagram

![Architecture Diagram](diagram/cf-architecture-diagramv2.png)

---  

## 2. Challenge Requirements (My Interpretation)

Based on the instructions provided, the solution needed to include:

- One VPC with CIDR `10.1.0.0/16`
- Three subnetted groups spread evenly across two Availability Zones
- Proper network segmentation
- Public management access
- Private application subnets
- Backend subnet
- EC2 running Apache in an Auto Scaling Group
- Application Load Balancer routing traffic to ASG hosts
- Management EC2 instance for SSH access
- Security groups enforcing least privilege
- Terraform modules or structured configurations
- Architecture diagram
- README including commentary, design reasoning, and operational improvements

I chose to build four subnets for the three groups instead of three to avoid combining application and backend workloads, and to satisfy AWS design principles that subnets do not span Availability Zones.

---

## 3. Architecture Decisions

Before writing any code, I created the architecture diagram. Working through a few versions helped me clearly define:

- Each subnet’s purpose
- How to separate public vs private routing
- The path of user traffic
- How the admin SSH path should work
- Where the ASG should span
- How the ALB fits into the design
- Which components belong in AZ1 vs AZ2

### Final Architecture Summary

#### VPC
- CIDR: `10.1.0.0/16`
- Attached Internet Gateway (IGW)

#### Availability Zones
**AZ1**
- Application Subnet A (private)
- Management Subnet (public)

**AZ2**
- Application Subnet B (private)
- Backend Subnet (private)

#### Public Routing
- Dedicated public route table for the management subnet
- Route: `0.0.0.0/0 → Internet Gateway`
- Enables secure admin access to the Management EC2 instance

#### Private Routing
- Application A, Application B, and Backend subnets use a private route table
- No direct Internet route
- Isolates application and backend layers

#### Traffic Flow

**Users**  
`Users → Internet → ALB → Application EC2s`

**Admin**  
`Admin → Internet → Internet Gateway → Public Route Table → Management EC2 → Application EC2`

#### Security Groups
- **ALB-SG:** allows HTTP/HTTPS from anywhere
- **APP-SG:** allows HTTP/HTTPS from ALB and SSH only from Management
- **MGMT-SG:** allows SSH only from my admin IP

This structure separates public entry points, private workloads, and administrative access.

---

## 4. Building the Terraform Configuration

I organized the Terraform configuration into multiple files:

### providers.tf
- AWS provider pointing to LocalStack
- Supports switching between LocalStack and real AWS

### variables.tf
Contains shared settings:
- CIDRs
- AMIs
- Instance types
- Boolean toggles:
  - `create_ec2_instances`
  - `create_alb_resources`
  - `enable_https`

### network.tf
- VPC
- Internet Gateway
- Public route table and association
- Private route table and associations
- Four subnets
- Security groups

### compute.tf
- Launch template for Apache EC2 instances
- Auto Scaling Group
- Optional Management EC2 instance

### alb.tf
- Application Load Balancer
- Target group
- HTTP listener
- Optional HTTPS listener (ACM)
- Conditional creation for LocalStack

### outputs.tf
- Resource IDs
- ALB DNS name (if enabled)

---

## 5. Local Testing With Docker and LocalStack

Tools used:

- Docker Desktop  
- LocalStack  
- Terraform CLI  

Commands:
terraform init
terraform plan
terraform apply


LocalStack confirmed:

- 1 VPC  
- Attached Internet Gateway  
- Public route table (`0.0.0.0/0 → IGW`)  
- 4 subnets  
- Route table associations  
- Security groups  

### EC2 Note for LocalStack

Because LocalStack cannot fully emulate EC2, ASG, or ALB behavior, I disabled those components:
create_ec2_instances = false
create_alb_resources = false
enable_https = false


In a full AWS deployment, these would be enabled.

---

## 6. Traffic Flow Explanation (With IGW Clarification)

### User Path
1. User sends an HTTP/HTTPS request  
2. Traffic enters through the Internet  
3. Routed through Internet Gateway  
4. ALB receives the request  
5. ALB forwards to an app EC2  
6. Response flows back through the ALB  

### Admin Path
1. Admin connects from trusted IP  
2. Traffic enters VPC through IGW  
3. Public route table forwards `0.0.0.0/0`  
4. Admin reaches the Management EC2  
5. Admin SSHs into private EC2s  
6. No direct public access to private subnets  

The IGW and public route table enable remote management access.

---

## 7. What I Would Deploy in Real AWS

- Enable EC2 creation  
- Enable ALB creation  
- Real ACM certificate for HTTPS  
- CloudWatch alarms (CPU, status checks, ALB health)  
- SSM Session Manager for admin access  
- ALB access logging  
- Autoscaling policies  
- NAT Gateway if backend needs outbound access  

---

## 8. Improvement Opportunities

### Security
- Force HTTPS  
- Add IAM roles  
- Use SSM Agent  
- Add NACLs  

### Availability
- NAT Gateway for private outbound traffic  
- Route 53 health checks  
- DynamoDB or RDS  

### Cost
- Use `t3.micro`  
- Disable ALB in dev  
- Scheduled scaling  

### Operations
- CloudWatch Logs  
- Backup strategy  
- Runbooks for events  

---

## 9. References & Independent Research Notes

Resources consulted:

- AWS VPC, Subnets, and Internet Gateway docs  
- AWS ALB and Auto Scaling docs  
- AWS Security Group and routing docs  
- AWS Well-Architected Framework  
- Public AWS architecture diagrams for consistency  

---

## Closing Summary

This challenge allowed me to design and build a clean, well-structured AWS environment using Terraform. Starting with the architecture diagram helped define each component before coding. The project is organized into modular Terraform layers, validated through LocalStack, and includes toggles for local vs AWS deployment.

This solution demonstrates:

- Clear architecture design  
- Separation of public and private workloads  
- Correct IGW and routing usage  
- Secure administrative access  
- Multi-AZ application layout  
- Terraform best practices  

The architecture diagram, full Terraform configuration, and detailed notes are included in this repository.
