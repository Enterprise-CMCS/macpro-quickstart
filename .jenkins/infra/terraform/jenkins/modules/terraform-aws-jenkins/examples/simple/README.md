# A simple use case for this module.

This is a working terraform example that builds a VPC and a Jenkins with a simple configuration.
Notably:
- The image variable is not specified, leaving the module default (jenkins/jenkins:lts-centos) in force.
- private subnets are passed to auto_scaling_subnets, indicating the Jenkins host should not be publicly accessible.
- public subnets are passed to load_balancer_subnets, indicating the load balancer should be publicly available to serve traffic to and from the private Jenkins host.
- fqdn, fqdn_certificate_arn, and fqdn_hosted_zone are not specified, indicating we want to access Jenkins over http at the AWS generated ALB domain name.

## Usage

Currently, there are a few prerequisites to running this code as is:
1. Update the key_name variable with the name of an EC2 key pair that already exists.  Create a key pair if needed.
2. Run:
```bash
$ terraform init -backend-config="bucket=<name of a state bucket>" -backend-config="key=<name of a state key"
$ terraform apply
```

## Notes

Please reference the inputs/outputs documentation in the top level README for more information.
