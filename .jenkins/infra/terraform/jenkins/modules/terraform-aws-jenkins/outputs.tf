
output "ecs_task_role_id" {
  description = "The IAM role ID attached to the ECS task.  This can be used to attach new policies to the running task."
  value       = aws_iam_role.ecs_task.id
}

output "ecs_host_role_id" {
  description = "The IAM role ID attached to the ECS host instance.  This can be used to attach new policies to the ECS host."
  value       = aws_iam_role.ecs_host.id
}

output "ecs_host_security_group_id" {
  description = "The ID of the security group used by the Jenkins master launch config.  Note:  With awsvpc networking, the host network configuration does not control the task network configuration; to do that, see ecs_task_security_group_id."
  value       = aws_security_group.ecs_host.id
}

output "ecs_task_security_group_id" {
  description = "The ID of the security group attached to the Jenkins task."
  value       = aws_security_group.ecs_task.id
}

output "ecs_cluster_id" {
  description = "The ID of the ECS cluster."
  value       = aws_ecs_cluster.cluster.id
}

output "ecs_task_private_endpoint" {
  description = "The privately accessible FQDN for the task.  This can be used by Jenkins slaves to reach the master privately."
  value       = "jenkins.${aws_service_discovery_private_dns_namespace.jenkins.name}"
}

output "jenkins_url" {
  description = "Jenkins' URL.  Put this in a browser."
  value       = "${local.scheme}://${local.endpoint}"
}
