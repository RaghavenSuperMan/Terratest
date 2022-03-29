provider "aws" {
  profile = "dce"
  region  = "us-east-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.50.0"
  name    = "bootstrap-vpc"
  cidr    = "20.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["20.0.1.0/24", "20.0.2.0/24"]
  public_subnets  = ["20.0.3.0/24", "20.0.4.0/24"]

  enable_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}