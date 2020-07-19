
output "jenkins_url" {
  description = "Jenkins' URL.  Put this in a browser."
  value       = module.jenkins.jenkins_url
}

output "jenkins_admin_username" {
  description = "Username for the initial Jenkins admin"
  value = var.jenkins_admin_username
}

output "jenkins_admin_password" {
  description = "Password for the initial Jenkins admin"
  value = random_password.admin_password.result
}
