############################
# Data / Locals
############################

# Default VPC & subnets (used when create_vpc = false)
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Latest Ubuntu 22.04 LTS (Canonical)
data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = var.ami_owners
  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }
}

locals {
  name_prefix = "${var.project_name}-${var.env}"

  # Conditionally reference IDs depending on whether we create a VPC
  vpc_id = var.create_vpc ? aws_vpc.this[0].id : data.aws_vpc.default.id

  subnet_id = var.create_vpc
    ? aws_subnet.public[0].id
    : data.aws_subnets.default_vpc_subnets.ids[0]

  tags_base = merge(
    {
      Name = local.name_prefix
    },
    var.common_tags
  )
}

############################
# Optional VPC + Networking
############################

resource "aws_vpc" "this" {
  count                = var.create_vpc ? 1 : 0
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags_base, { Component = "vpc" })
}

resource "aws_internet_gateway" "this" {
  count  = var.create_vpc ? 1 : 0
  vpc_id = aws_vpc.this[0].id

  tags = merge(local.tags_base, { Component = "igw" })
}

resource "aws_subnet" "public" {
  count                   = var.create_vpc ? 1 : 0
  vpc_id                  = aws_vpc.this[0].id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = var.enable_public_ip

  tags = merge(local.tags_base, { Component = "subnet-public" })
}

resource "aws_route_table" "public" {
  count  = var.create_vpc ? 1 : 0
  vpc_id = aws_vpc.this[0].id

  tags = merge(local.tags_base, { Component = "rt-public" })
}

resource "aws_route" "public_inet" {
  count                  = var.create_vpc ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public_assoc" {
  count          = var.create_vpc ? 1 : 0
  subnet_id      = aws_subnet.public[0].id
  route_table_id = aws_route_table.public[0].id
}

############################
# Security Group (22, 80)
############################

resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = local.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags_base, { Component = "sg-web" })
}

############################
# EC2 Instance
############################

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu_2204.id
  instance_type               = var.instance_type
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = var.enable_public_ip

  # Optional SSH key pair
  key_name = length(var.key_name) > 0 ? var.key_name : null

  # User data will bootstrap Apache/Python later
  # (kept here to reference your repo URL even if the script is empty for now)
  user_data = templatefile("${path.module}/../deploy/scripts/user_data.sh", {
    repo_url = var.repo_url
  })

  root_block_device {
    volume_size = var.volume_size_gb
    volume_type = "gp3"
  }

  tags = merge(local.tags_base, { Component = "ec2-web" })
}

############################
# Optional Elastic IP
############################

resource "aws_eip" "web" {
  count    = var.allocate_eip ? 1 : 0
  instance = aws_instance.web.id
  domain   = "vpc"

  tags = merge(local.tags_base, { Component = "eip-web" })
}

############################
# Helpful Outputs (mirrors outputs.tf)
############################

output "instance_public_ip" {
  value       = aws_instance.web.public_ip
  description = "Public IP (if associate_public_ip_address = true)"
}

output "elastic_ip" {
  value       = var.allocate_eip ? aws_eip.web[0].public_ip : null
  description = "Elastic IP (if allocate_eip = true)"
}

output "website_url" {
  value       = "http://${coalesce(try(aws_eip.web[0].public_ip, null), aws_instance.web.public_ip)}"
  description = "Convenience URL"
}
