terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

terraform {
  backend "s3" {
    bucket = "mypetbuckettw"
    key    = "tf-state"
    region = "us-east-1"
  }
}


provider "aws" {
  region = var.AWS_REGION
}

