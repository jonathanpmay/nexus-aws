provider "aws" {
    version = "2.49.0"
    region = "us-east-1"
}

terraform {
    backend "s3" {
        bucket = "nexus-backend"
        key = "nexus.terraform.tfstate"
        region = "us-east-1"
    }
}