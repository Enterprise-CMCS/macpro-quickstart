##############################################
# Build this example in US East (N. Virginia)
##############################################

provider "aws" {
  region  = "us-east-1"
  version = "2.58.0"
}

terraform {
  backend "s3" {
    region  = "us-east-1"
    encrypt = true
    key     = "tf_state/infrastructure/jenkins"
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  blacklisted_names = ["us-east-1e"]
}

provider "random" {
  version = "2.2.0"
}
