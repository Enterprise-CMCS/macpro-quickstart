
output "jenkins_url" {
  description = "Jenkins' URL.  Put this in a browser."
  value       = module.jenkins.jenkins_url
}
