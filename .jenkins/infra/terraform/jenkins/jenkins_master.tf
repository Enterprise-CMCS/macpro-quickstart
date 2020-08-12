
#########################################
# Build Jenkins Master as an ECS Service
#########################################

module "jenkins" {
  source                         = "git::https://github.com/collabralink-technology/terraform-aws-jenkins.git?ref=2.2.4"
  name                           = var.name
  vpc_id                         = module.vpc_management.vpc_id
  host_instance_type             = var.host_instance_type
  auto_scaling_subnets           = [module.vpc_management.private_subnets[0]]
  auto_scaling_availability_zone = data.aws_availability_zones.available.names[0]
  load_balancer_subnets          = module.vpc_management.public_subnets
  image                          = aws_ecr_repository.jenkins.repository_url
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = module.jenkins.ecs_host_role_id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

###################################
# Build and push the Jenkins image
###################################

# Creates an ECR image repository to hold the jenkins image.
resource "aws_ecr_repository" "jenkins" {
  name = var.jenkins_ecr_repo_name
}

# Check docker files for changes
module "path_hash" {
  source = "github.com/claranet/terraform-path-hash?ref=v1.0.0"
  path   = "./jenkins_image"
}

# Generate a random password for the initial admin
resource "random_password" "admin_password" {
  length           = 12
  min_upper = 1
  min_lower = 1
  min_numeric = 1
  min_special = 1
  override_special = "*%"
}

resource "local_file" "jenkins_yml" {
  content = templatefile(
    "${path.module}/jenkins_image/files/casc_configs/jenkins.yml.tpl", {
      jenkins_url         = "${module.jenkins.jenkins_url}/",
      admin_username = var.jenkins_admin_username,
      admin_password = random_password.admin_password.result,
      slave_cluster_arn   = aws_ecs_cluster.slave_cluster.arn,
      region              = data.aws_region.current.name,
      task_subnets        = module.vpc_management.private_subnets,
      task_security_group = aws_security_group.jenkins_slave.id
      ec2_jnlp_slave = {
        label       = "ec2-jnlp-slave"
        family      = aws_ecs_task_definition.ec2_jnlp_slave.family
        launch_type = join(",", aws_ecs_task_definition.ec2_jnlp_slave.requires_compatibilities)
      }
      fargate_jnlp_slave = {
        label       = "fargate-jnlp-slave"
        family      = aws_ecs_task_definition.fargate_jnlp_slave.family
        launch_type = join(",", aws_ecs_task_definition.fargate_jnlp_slave.requires_compatibilities)
      }
      jenkins_alternative_url      = "http://${module.jenkins.ecs_task_private_endpoint}:8080"
      git_https_clone_url          = var.git_https_clone_url
      git_username_for_jenkins     = var.git_username_for_jenkins
      git_access_token_for_jenkins = var.git_access_token_for_jenkins
      application_bucket           = var.bucket
      slave_security_group         = aws_security_group.jenkins_slave.id
  })
  filename = "${path.module}/jenkins_image/files/casc_configs/jenkins.yml"
}

# Builds and pushes the jenkins image to ECR.
resource "null_resource" "build_jenkins_image" {
  triggers = {
    new_ecr_repo          = aws_ecr_repository.jenkins.repository_url
    jenkins_image_changes = module.path_hash.result
    updated_jenkins_yml   = local_file.jenkins_yml.content
  }
  provisioner "local-exec" {
    command = "chmod -R 755 ./jenkins_image && cd jenkins_image && ./deploy-image.sh ${aws_ecr_repository.jenkins.repository_url} ${var.jenkins_ecr_repo_name}"
  }
  depends_on = [local_file.jenkins_yml]
}
