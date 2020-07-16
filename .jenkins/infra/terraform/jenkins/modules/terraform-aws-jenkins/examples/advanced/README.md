# Advanced implementation

In short, this example is ab ECS Jenkins installation with full slave support (ecs fargate and ec2), google oauth, plugins, and other config out of the box.
This can run Appian DevOps pipelines immediately.

This example does a few extra things:
- An ECS Cluster for Jenkins Slaves is built
- An autoscaling group is built to serve as ECS hosts for EC2 tasks in that slave cluster.
- An ECS Task of type EC2 is built to run jenkins jobs.
- An ECS Task of type FARGATE is built to run jenkins jobs.
- A docker image is built locally.
- The image is configured with a plugins.txt that tells the image what plugins we'd like installed.
- The image is loaded with Configuration as Code (CasC) to configure a lot of stuff on Jenkins.
- CasC configures the ECS Slave clusters with the ECS Cloud Plugin.
- CasC configures Google Oauth (makes sense for us, entirely optional) for sensible auth out of the gate.

Recommended usage:
- Copy/paste/download this example directory
- Make a copy of terraform.tfvars.example and name it terraform.tfvars
- Fill out terraform.tfvars with your Information
- terraform init
- terraform apply
- Remove the authorizationStrategy section in docker_jenkins/files/casc_configs/jenkins.yml.tpl (see explanation below)
- terraform apply

^^ Explanation:  We want authorization bootstrapped onto Jenkins so we never have it unsecured.  However, we want to control authorization from the Jenkins console moving forward... allowing person A, B, C or group Admin permissions x,y,z should be done in the console.  If we left the authorizationStrategy in the CasC config, the authorization changes made in the console would be overwritten if/when the task/container restarts.  This is entirely optional, and just one way to do things.
