terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket       = "sue-aws-student-01-tfstate"
    key          = "lab/terraform.tfstate"
    region       = "eu-west-1"
    profile      = "sue-aws-student-01"
    use_lockfile = true
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile

  default_tags {
    tags = {
      Course    = "CEC-2026"
      ManagedBy = "terraform"
    }
  }
}
