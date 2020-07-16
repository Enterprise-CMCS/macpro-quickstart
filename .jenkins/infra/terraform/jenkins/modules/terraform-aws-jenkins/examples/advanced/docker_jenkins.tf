
# Creates an ECR image repository to hold the jenkins image.
resource "aws_ecr_repository" "jenkins" {
  name = var.jenkins_ecr_repo_name
}

# Check docker files for changes
module "path_hash" {
  source = "github.com/claranet/terraform-path-hash?ref=v0.2.0"
  path   = "./docker_jenkins"
}

resource "local_file" "jenkins_yml" {
  content = templatefile(
    "${path.module}/docker_jenkins/files/casc_configs/jenkins.yml.tpl", {
      jenkins_url         = "https://${var.jenkins_fqdn}/",
      slave_cluster_arn   = aws_ecs_cluster.slave_cluster.arn,
      region              = data.aws_region.current.name,
      task_subnets        = module.vpc.private_subnets,
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
      fargate_appian_slave = {
        label       = "fargate-appian-slave"
        family      = aws_ecs_task_definition.fargate_appian_slave.family
        launch_type = join(",", aws_ecs_task_definition.fargate_appian_slave.requires_compatibilities)
      }
      jenkins_alternative_url            = "http://${module.jenkins.ecs_task_private_endpoint}:8080"
      jenkins_google_oauth_client_id     = var.jenkins_google_oauth_client_id
      jenkins_google_oauth_client_secret = var.jenkins_google_oauth_client_secret
      jenkins_google_oauth_domain        = var.jenkins_google_oauth_domain
  })
  filename = "${path.module}/docker_jenkins/files/casc_configs/jenkins.yml"
}

# Builds and pushes the jenkins image to ECR.
resource "null_resource" "build_jenkins_image" {
  triggers = {
    new_ecr_repo           = aws_ecr_repository.jenkins.repository_url
    docker_jenkins_changes = module.path_hash.result
    updated_jenkins_yml    = local_file.jenkins_yml.content
  }
  provisioner "local-exec" {
    command = "chmod -R 755 ./docker_jenkins && cd docker_jenkins && ./deploy-image.sh ${aws_ecr_repository.jenkins.repository_url} ${var.jenkins_ecr_repo_name}"
  }
  depends_on = [local_file.jenkins_yml]
}
