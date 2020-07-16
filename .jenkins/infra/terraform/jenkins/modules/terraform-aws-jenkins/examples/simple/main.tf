##############################################
# Build this example in US East (N. Virginia)
##############################################

provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    region  = "us-east-1"
    encrypt = true
    key     = "gitlab/collabralink/delivery/terraform-aws-jenkins/examples/simple"
  }
}

###############################
# Build a VPC for this example
###############################
locals {
  vpc_cidr = "10.10.0.0/16"
}

data "aws_availability_zones" "available" {}

resource "null_resource" "subnets" {
  count = length(data.aws_availability_zones.available.names)
  triggers = {
    private_subnet = cidrsubnet(local.vpc_cidr, 8, count.index + 1)
    public_subnet  = cidrsubnet(local.vpc_cidr, 8, count.index + 101)
  }
}

module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "2.9.0"
  name                 = terraform.workspace
  cidr                 = local.vpc_cidr
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = null_resource.subnets.*.triggers.private_subnet
  public_subnets       = null_resource.subnets.*.triggers.public_subnet
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true
  single_nat_gateway   = true
}

#########################################
# Build Jenkins Master as an ECS Service
#########################################

module "jenkins" {
  source                         = "../.."
  name                           = terraform.workspace
  vpc_id                         = module.vpc.vpc_id
  host_instance_type             = "t3a.small"
  auto_scaling_subnets           = [module.vpc.private_subnets[0]]
  auto_scaling_availability_zone = data.aws_availability_zones.available.names[0]
  load_balancer_subnets          = module.vpc.public_subnets
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = module.jenkins.ecs_host_role_id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
