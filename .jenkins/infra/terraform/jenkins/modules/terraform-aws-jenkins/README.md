# Jenkins ECS Terraform Module

[![pipeline status](https://gitlab.com/mdialcollabralinkcom-freeze/terraform-aws-jenkins/badges/master/pipeline.svg)](https://gitlab.com/mdialcollabralinkcom-freeze/terraform-aws-jenkins/-/commits/master)

A containerized Jenkins Master implementation orchestrated by ECS.
- An EC2 Auto Scaling Group is created to ensure an ECS Host is available.
- A Jenkins Master ECS Service is created to keep Jenkins up and running, despite host failure or sudden unavailability.
- Persistence of jenkins_home is ensured with a reattachable EBS volume orchestrated by a docker plugin.
- Optionally, a snapshot of an existing jenkins_home volume may be passed to create a new Jenkins from existing Jenkins config.
- Jenkins Master is fronted with an Application Load Balancer performing TLS termination.
- A Data Lifecycle Management policy is created to automate the creation and lifecycle of jenkins_home EBS Snapshots.

## Terraform versions

Terraform 0.12 +


## Usage
See a common implementation (complete with VPC) [here!](examples/common)

```hcl
module "jenkins" {
  source                         = "git::ssh://git@gitlab.com/mdialcollabralinkcom-freeze/terraform-aws-jenkins.git"
  name                           = "jenkins"
  vpc_id                         = "vpc-abc123"
  host_instance_type             = "t3.large"
  auto_scaling_subnets           = ["subnet-123afb39d0dagdv32","subnet-004aff23j60dwez897"]
  auto_scaling_availability_zone = "us-east-1a"
  load_balancer_subnets          = ["subnet-277afb45g0dagdv32","subnet-3288vvssdwezf221xv"]
  fqdn                           = "jenkins.mydomain.com"
  fqdn_hosted_zone               = "mydomain.com"
  fqdn_certificate_arn           = "arn:aws:acm:us-east-1:02333354974:certificate/dsav3ea6-6ff5-31e8-93cc-8badfdvzf1345"
}
```


## Examples
[Simple](examples/simple) and [advanced](examples/advanced) examples are included in the examples folder.


## Contributing / To-Do

See current open [issues](https://gitlab.com/mdialcollabralinkcom-freeze/terraform-aws-jenkins/issues) or check out the [board](https://gitlab.com/mdialcollabralinkcom-freeze/terraform-aws-jenkins/-/boards)

Please feel free to open new issues for defects or enhancements.

Merge requests are being accepted.


## Notes

WIP


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| auto\_scaling\_availability\_zone | The single AZ into which Jenkins should be launched. | string | n/a | yes |
| auto\_scaling\_subnets | The subnets for the Jenkins auto scaling group into which Jenkins may be placed. | list | n/a | yes |
| fqdn | The FQDN with which jenkins is accessed; leave blank to simnply access Jenkins with the generated DNS name of the load balancer.  If set, fqdn_hosted_zone is required. | string | `""` | no |
| fqdn\_certificate\_arn | The arn of the ACM certificate that gets applied to jenkins ALB.  Setting this effectively enables SSL.  The certificate's domain must be valid for the set fqdn and fqdn_hosted_one.  If set, fqdn and fqdn_hosted_zone are required. | string | `""` | no |
| fqdn\_hosted\_zone | The hosted zone in which to create the route 53 record for jenkins.  The fqdn should fall inside this hosted zone.  If set, fqdn is required | string | `""` | no |
| host\_instance\_type | Jenkins master instance type | string | `"m5.xlarge"` | no |
| host\_key\_name | Name of an existing EC2 Key Pair to attach to the Jenkins Host. | string | `""` | no |
| host\_security\_groups | Additional security groups to add to the jenkins host.  Warning:  These will only take affect when the next EC2 instance is launched by autoscaling.  You may want to use the ecs_host_security_group_id output to attach a new rule externally. | list | `[]` | no |
| image | Jenkins image to use | string | `"jenkins/jenkins:lts-centos"` | no |
| jenkins\_home\_size | The size in GB for the jenkins_home volume.  If using with jenkins_home_snapshot_id, size must be greater than the snapshot size. | string | `"50"` | no |
| jenkins\_home\_snapshot\_id | The snapshot ID from which to build the ebs volume. | string | `""` | no |
| load\_balancer\_internal | Set to true to create a publicly-resolvable but non-publicly-accessible load balancer for jenkins.  If set to true, load_balancer_subnets must be given private subnets. | bool | `"false"` | no |
| load\_balancer\_subnets | The subnets the load balancer will include. | list | n/a | yes |
| name | Name for the Jenkins installation.  This is used in prefixes and suffixes. | string | n/a | yes |
| prefix | Prefix used in naming resources | string | `"jenkins"` | no |
| vpc\_id | VPC ID into which Jenkins is launched. | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| ecs\_cluster\_id | The ID of the ECS cluster. |
| ecs\_host\_role\_id | The IAM role ID attached to the ECS host instance.  This can be used to attach new policies to the ECS host. |
| ecs\_host\_security\_group\_id | The ID of the security group used by the Jenkins master launch config.  Note:  With awsvpc networking, the host network configuration does not control the task network configuration; to do that, see ecs_task_security_group_id. |
| ecs\_task\_private\_endpoint | The privately accessible FQDN for the task.  This can be used by Jenkins slaves to reach the master privately. |
| ecs\_task\_role\_id | The IAM role ID attached to the ECS task.  This can be used to attach new policies to the running task. |
| ecs\_task\_security\_group\_id | The ID of the security group attached to the Jenkins task. |
| jenkins\_url | Jenkins' URL.  Put this in a browser. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


## Authors

Currently maintained by [these contributors](https://gitlab.com/mdialcollabralinkcom-freeze/terraform-aws-jenkins/-/graphs/master) at Collabralink Technologies, Inc.
Module managed by [Mike Dial](https://gitlab.com/mdialcollabralinkcom).

## License

Copyright, Collabralink Technologies Inc.
