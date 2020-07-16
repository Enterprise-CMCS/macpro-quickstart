# This variables.tf file serves to simply initialize variables used by this example.
# These variables should be set in a terraform.tfvars file.
# See the terraform.tfvars.example file for guidance.

variable "name" {}
variable "vpc_cidr" {}
variable "host_instance_type" {}
variable "jenkins_fqdn" {}
variable "jenkins_fqdn_certificate_arn" {}
variable "jenkins_hosted_zone" {}
variable "jenkins_ecr_repo_name" {}
variable "jenkins_google_oauth_client_id" {}
variable "jenkins_google_oauth_client_secret" {}
variable "jenkins_google_oauth_domain" {}
