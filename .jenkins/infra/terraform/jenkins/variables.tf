
variable "name" {
  description = "Any name that makes sense; used to prefix and/or suffix a lot of AWS resources built by terraform."
  default     = "acme"
}

variable "host_instance_type" {
  description = "The Jenkins master ec2 instance type."
  default     = "t3.medium"
}
variable "jenkins_ecr_repo_name" {
  description = "The ECR repository name to hold the Jenkins image.  This only needs to be unique in the AWS account, not globally."
  default     = "jenkins-acme"
}

variable "git_https_clone_url" {}
variable "git_username_for_jenkins" {}
variable "git_access_token_for_jenkins" {}
variable "bucket" {}
