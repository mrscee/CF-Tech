variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "app_subnet_a_cidr" {
  description = "Application subnet in AZ1"
  type        = string
  default     = "10.1.1.0/24"
}

variable "app_subnet_b_cidr" {
  description = "Application subnet in AZ2"
  type        = string
  default     = "10.1.4.0/24" # pick any free /24 inside 10.1.0.0/16
}

variable "mgmt_subnet_cidr" {
  description = "Management subnet in AZ1 (public)"
  type        = string
  default     = "10.1.2.0/24"
}

variable "backend_subnet_cidr" {
  description = "Backend subnet in AZ2 (private)"
  type        = string
  default     = "10.1.3.0/24"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH to the management instance"
  type        = string
  default     = "0.0.0.0/0" # for LocalStack; in real AWS use your IP /32
}
variable "create_ec2_instances" {
  description = "Whether to create EC2 instances (disable for LocalStack to avoid hangs)"
  type        = bool
  default     = false
}
variable "enable_https" {
  description = "Enable ACM certificate and HTTPS listener on the ALB (disabled for LocalStack)"
  type        = bool
  default     = false
}
variable "create_alb_resources" {
  description = "Whether to create ALB, target group, and listeners (disable for LocalStack)"
  type        = bool
  default     = false
}
