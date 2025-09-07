# Provider configuration
provider "aws" {
  region = var.aws_region

  # Apply your common tags to all supported AWS resources
  default_tags {
    tags = var.common_tags
  }
}
