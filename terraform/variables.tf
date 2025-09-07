############################
# General / Project
############################

variable "env" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Base name for resources"
  type        = string
}

############################
# AWS Settings
############################

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "availability_zone" {
  description = "AZ for subnet placement (e.g. us-east-1a)"
  type        = string
}

############################
# EC2 Instance
############################

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair for SSH (leave empty to disable SSH access)"
  type        = string
  default     = ""
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to SSH (22) into instance"
  type        = string
}

variable "repo_url" {
  description = "Git repo URL to clone in user_data"
  type        = string
}

variable "volume_size_gb" {
  description = "Root volume size (GB)"
  type        = number
  default     = 10
}

############################
# Networking
############################

variable "create_vpc" {
  description = "Whether to create a new VPC (true) or use default VPC (false)"
  type        = bool
  default     = false
}

variable "vpc_cidr" {
  description = "CIDR block for new VPC (if create_vpc = true)"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for public subnet (if create_vpc = true)"
  type        = string
  default     = "10.10.1.0/24"
}

variable "enable_public_ip" {
  description = "Whether to auto-assign public IP for instances"
  type        = bool
  default     = true
}

variable "allocate_eip" {
  description = "Whether to allocate an Elastic IP for the instance"
  type        = bool
  default     = false
}

############################
# AMI Lookup
############################

variable "ami_owners" {
  description = "List of owners to filter AMI (Canonical for Ubuntu)"
  type        = list(string)
  default     = ["099720109477"]
}

variable "ami_name_filter" {
  description = "Name filter for AMI lookup"
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}

############################
# Common Tags
############################

variable "common_tags" {
  description = "Map of common tags to apply to resources"
  type        = map(string)
  default     = {}
}
