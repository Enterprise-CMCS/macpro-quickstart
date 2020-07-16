# Define some local variables as a convenience
locals {
  vpc_cidr_management            = "10.10.0.0/16"
  vpc_cidr_dev                   = "10.11.0.0/16"
  vpc_cidr_preprod               = "10.12.0.0/16"
  vpc_cidr_prod                  = "10.13.0.0/16"
  route_table_ids_vpc_management = concat(module.vpc_management.private_route_table_ids, module.vpc_management.public_route_table_ids)
  route_table_ids_vpc_dev        = concat(module.vpc_dev.private_route_table_ids, module.vpc_dev.public_route_table_ids)
  route_table_ids_vpc_preprod    = concat(module.vpc_preprod.private_route_table_ids, module.vpc_preprod.public_route_table_ids)
  route_table_ids_vpc_prod       = concat(module.vpc_prod.private_route_table_ids, module.vpc_prod.public_route_table_ids)
}

####################################################################################################
# Create the Management VPC for shared services, like Jenkins
####################################################################################################
resource "null_resource" "subnets" {
  count = length(data.aws_availability_zones.available.names)
  triggers = {
    private_subnet = cidrsubnet(local.vpc_cidr_management, 8, count.index + 1)
    public_subnet  = cidrsubnet(local.vpc_cidr_management, 8, count.index + 101)
  }
}

module "vpc_management" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "2.39.0"
  name                 = var.name
  cidr                 = local.vpc_cidr_management
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = null_resource.subnets.*.triggers.private_subnet
  public_subnets       = null_resource.subnets.*.triggers.public_subnet
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true
  single_nat_gateway   = true
}
####################################################################################################


####################################################################################################
# Create the dev VPC and peer to the jenkins VPC
####################################################################################################
resource "null_resource" "subnets_dev" {
  count = length(data.aws_availability_zones.available.names)
  triggers = {
    private_subnet = cidrsubnet(local.vpc_cidr_dev, 8, count.index + 1)
    public_subnet  = cidrsubnet(local.vpc_cidr_dev, 8, count.index + 101)
  }
}

module "vpc_dev" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "2.39.0"
  name                 = "dev"
  cidr                 = local.vpc_cidr_dev
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = null_resource.subnets_dev.*.triggers.private_subnet
  public_subnets       = null_resource.subnets_dev.*.triggers.public_subnet
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_s3_endpoint   = false
  private_subnet_tags = {
    "Tier" : "Private"
  }
  public_subnet_tags = {
    "Tier" : "Public"
  }
}

resource "aws_vpc_peering_connection" "dev" {
  peer_owner_id = data.aws_caller_identity.current.account_id
  vpc_id        = module.vpc_dev.vpc_id
  peer_vpc_id   = module.vpc_management.vpc_id
  auto_accept   = true
  accepter {
    allow_remote_vpc_dns_resolution = true
  }
  requester {
    allow_remote_vpc_dns_resolution = true
  }
  tags = {
    Name = "VPC Peering between dev and jenkins"
  }
}

resource "aws_route" "dev_primary2secondary" {
  count                     = length(local.route_table_ids_vpc_dev)
  route_table_id            = local.route_table_ids_vpc_dev[count.index]
  destination_cidr_block    = module.vpc_management.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.dev.id
}

resource "aws_route" "dev_secondary2primary" {
  count                     = length(local.route_table_ids_vpc_management)
  route_table_id            = local.route_table_ids_vpc_management[count.index]
  destination_cidr_block    = module.vpc_dev.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.dev.id
}
####################################################################################################


####################################################################################################
# Create the preprod VPC and peer to the jenkins VPC
####################################################################################################

resource "null_resource" "subnets_preprod" {
  count = length(data.aws_availability_zones.available.names)
  triggers = {
    private_subnet = cidrsubnet(local.vpc_cidr_preprod, 8, count.index + 1)
    public_subnet  = cidrsubnet(local.vpc_cidr_preprod, 8, count.index + 101)
  }
}

module "vpc_preprod" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "2.39.0"
  name                 = "preprod"
  cidr                 = local.vpc_cidr_preprod
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = null_resource.subnets_preprod.*.triggers.private_subnet
  public_subnets       = null_resource.subnets_preprod.*.triggers.public_subnet
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_s3_endpoint   = false
  private_subnet_tags = {
    "Tier" : "Private"
  }
  public_subnet_tags = {
    "Tier" : "Public"
  }
}

resource "aws_vpc_peering_connection" "preprod" {
  peer_owner_id = data.aws_caller_identity.current.account_id
  peer_vpc_id   = module.vpc_management.vpc_id
  vpc_id        = module.vpc_preprod.vpc_id
  auto_accept   = true
  accepter {
    allow_remote_vpc_dns_resolution = true
  }
  requester {
    allow_remote_vpc_dns_resolution = true
  }
  tags = {
    Name = "VPC Peering between preprod and jenkins"
  }
}

resource "aws_route" "preprod_primary2secondary" {
  count                     = length(local.route_table_ids_vpc_preprod)
  route_table_id            = local.route_table_ids_vpc_preprod[count.index]
  destination_cidr_block    = module.vpc_management.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.preprod.id
}

resource "aws_route" "preprod_secondary2primary" {
  count                     = length(local.route_table_ids_vpc_management)
  route_table_id            = local.route_table_ids_vpc_management[count.index]
  destination_cidr_block    = module.vpc_preprod.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.preprod.id
}
####################################################################################################


####################################################################################################
# Create the prod VPC and peer to the jenkins VPC
####################################################################################################
resource "null_resource" "subnets_prod" {
  count = length(data.aws_availability_zones.available.names)
  triggers = {
    private_subnet = cidrsubnet(local.vpc_cidr_prod, 8, count.index + 1)
    public_subnet  = cidrsubnet(local.vpc_cidr_prod, 8, count.index + 101)
  }
}

module "vpc_prod" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "2.39.0"
  name                 = "prod"
  cidr                 = local.vpc_cidr_prod
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = null_resource.subnets_prod.*.triggers.private_subnet
  public_subnets       = null_resource.subnets_prod.*.triggers.public_subnet
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_s3_endpoint   = false
  private_subnet_tags = {
    "Tier" : "Private"
  }
  public_subnet_tags = {
    "Tier" : "Public"
  }
}

resource "aws_vpc_peering_connection" "prod" {
  peer_owner_id = data.aws_caller_identity.current.account_id
  peer_vpc_id   = module.vpc_management.vpc_id
  vpc_id        = module.vpc_prod.vpc_id
  auto_accept   = true
  accepter {
    allow_remote_vpc_dns_resolution = true
  }
  requester {
    allow_remote_vpc_dns_resolution = true
  }
  tags = {
    Name = "VPC Peering between prod and jenkins"
  }
}

resource "aws_route" "prod_primary2secondary" {
  count                     = length(local.route_table_ids_vpc_prod)
  route_table_id            = local.route_table_ids_vpc_prod[count.index]
  destination_cidr_block    = module.vpc_management.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.prod.id
}

resource "aws_route" "prod_secondary2primary" {
  count                     = length(local.route_table_ids_vpc_management)
  route_table_id            = local.route_table_ids_vpc_management[count.index]
  destination_cidr_block    = module.vpc_prod.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.prod.id
}
####################################################################################################
