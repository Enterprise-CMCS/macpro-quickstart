###########################################################
# Build an ECS Cluster to serve as a Jenkins Slave cluster
###########################################################

# Slave ECS Cluster for both EC2 and Fargate tasks
resource "aws_ecs_cluster" "slave_cluster" {
  name               = "jenkins-slave-${var.name}"
  capacity_providers = ["FARGATE"]
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = "100"
  }
}

# Allow master to launch tasks in the slave cluster, attaching a policy to master's role.
resource "aws_iam_role_policy" "slave_ecs_cluster_policy_for_master" {
  name = "jenkins-slave-ecs-cluster-policy-for-master-${var.name}"
  role = module.jenkins.ecs_task_role_id
  policy = templatefile("${path.module}/templates/slave-ecs-cluster-policy-for-master.json.tpl", {
    region       = data.aws_region.current.name
    account_id   = data.aws_caller_identity.current.account_id
    cluster_name = module.jenkins.ecs_cluster_id
  })
}

# Security group for all slaves, allowing outbound internet access.
resource "aws_security_group" "jenkins_slave" {
  name        = "jenkins-slave-${var.name}"
  description = "Allow Jenkins Slaves outbound internet access"
  vpc_id      = module.vpc_management.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Tell Jenkins master to allow 8080 traffic from slaves.
resource "aws_security_group_rule" "jenkins_slave_8080" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.jenkins_slave.id
  security_group_id        = module.jenkins.ecs_task_security_group_id
}

# Tell Jenkins master to allow 50000 JNLP traffic from slaves.
resource "aws_security_group_rule" "jenkins_slave_50000" {
  type                     = "ingress"
  from_port                = 50000
  to_port                  = 50000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.jenkins_slave.id
  security_group_id        = module.jenkins.ecs_task_security_group_id
}

# re: EC2 tasks.  Find the most recent ECS optimized
data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name = "name"
    values = [
      "amzn2-ami-ecs-hvm-*-x86_64-ebs",
    ]
  }
  filter {
    name = "owner-alias"
    values = [
      "amazon",
    ]
  }
}

# re: EC2 tasks.  IAM role for ECS hosts.
resource "aws_iam_role" "ecs_host" {
  name               = "jenkins-slave-ecs-host-${var.name}"
  assume_role_policy = file("./files/assume-role-policy-ec2.json")
}

# re: EC2 tasks.  Attach IAM policy to the ECS hosts' role.
resource "aws_iam_role_policy" "ecs_host" {
  name   = "jenkins-slave-ecs-host-${var.name}"
  role   = aws_iam_role.ecs_host.id
  policy = file("./files/ecs-host-policy.json")
}

resource "aws_iam_role_policy_attachment" "ssm_slave_host" {
  role       = aws_iam_role.ecs_host.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# re: EC2 tasks.  IAM instance profile to be attached to EC2 instances.
resource "aws_iam_instance_profile" "ecs_host" {
  name = "jenkins-slave-ecs-host${var.name}"
  path = "/"
  role = aws_iam_role.ecs_host.name
}

# re: EC2 tasks.  Auto scaling launch configuration, configuring how ECS instances should be launched.
resource "aws_launch_configuration" "ecs_host" {
  name_prefix                 = "jenkins-slave-ecs-host-${var.name}"
  image_id                    = data.aws_ami.ecs_optimized.id
  instance_type               = "t3a.small"
  security_groups             = flatten([aws_security_group.jenkins_slave.id])
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ecs_host.name
  user_data = templatefile("${path.module}/templates/user_data.tpl", {
    ecs_cluster_name = aws_ecs_cluster.slave_cluster.id
    ebs_region       = data.aws_region.current.name
  })
  root_block_device {
    volume_type = "gp2"
    volume_size = 200
  }
  lifecycle {
    create_before_destroy = true
  }
}

# re: EC2 tasks.  Auto Scaling group for EC2 instances hosting ECS tasks of type EC2.
resource "aws_autoscaling_group" "ecs_host" {
  name                      = "jenkins-slave-ecs-host-${var.name}"
  min_size                  = 0
  max_size                  = 2
  desired_capacity          = 1
  health_check_type         = "EC2"
  health_check_grace_period = 300
  launch_configuration      = aws_launch_configuration.ecs_host.name
  vpc_zone_identifier       = module.vpc_management.private_subnets
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
  tags = [
    {
      key                 = "Name"
      value               = "jenkins-slave-ecs-host-${var.name}"
      propagate_at_launch = true
    },
  ]
}

# Create a (blank) role for ECS tasks.
resource "aws_iam_role" "ecs_task" {
  name               = "jenkins-slave-role-${var.name}"
  assume_role_policy = file("./files/assume-role-policy-ecs-tasks.json")
}

resource "aws_iam_policy" "pipeline_runner" {
  name   = "jenkins-slave-ecs-task-${var.name}"
  policy = file("./files/pipeline-runner-policy.json")
}

resource "aws_iam_role_policy_attachment" "pipeline_runner" {
  role       = aws_iam_role.ecs_task.id
  policy_arn = aws_iam_policy.pipeline_runner.arn
}

# ECS EC2 JNLP Slave - Create task definition
resource "aws_ecs_task_definition" "ec2_jnlp_slave" {
  family                   = "ec2-jnlp-slave-${var.name}"
  container_definitions    = file("${path.module}/files/task-def-jenkins-jnlp-slave-ec2.txt")
  task_role_arn            = aws_iam_role.ecs_task.arn
  requires_compatibilities = ["EC2"]
  network_mode             = "host"
  volume {
    name      = "docker_sock"
    host_path = "/var/run/docker.sock"
  }
  volume {
    name      = "docker_bin"
    host_path = "/usr/bin/docker"
  }
  volume {
    name      = "docker_compose_bin"
    host_path = "/usr/local/bin/docker-compose"
  }
  volume {
    name      = "docker_compose_bin"
    host_path = "/usr/local/bin/docker-compose"
  }
  volume {
    name      = "home_jenkins_workspace"
    host_path = "/home/jenkins/workspace"
  }
}

# ECS EC2 JNLP Slave - Allow Jenkins Master permission to launch task(s)
resource "aws_iam_role_policy" "slave_ec2_ecs_task_definition_policy_for_master" {
  name = "ec2-jnlp-slave-launch-permission-${var.name}"
  policy = templatefile("${path.module}/templates/slave-ecs-task-definition-policy-for-master.json.tpl", {
    region               = data.aws_region.current.name
    account_id           = data.aws_caller_identity.current.account_id
    task_definition_name = aws_ecs_task_definition.ec2_jnlp_slave.family
  })
  role = module.jenkins.ecs_task_role_id
}

# ECS EC2 JNLP Slave - Create task definition
resource "aws_ecs_task_definition" "fargate_jnlp_slave" {
  family                   = "fargate-jnlp-slave-${var.name}"
  container_definitions    = file("${path.module}/files/task-def-jenkins-jnlp-slave-fargate.txt")
  task_role_arn            = aws_iam_role.ecs_task.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 4096
}

# ECS Fargate JNLP Slave - Allow Jenkins Master permission to launch task(s)
resource "aws_iam_role_policy" "slave_fargate_ecs_task_definition_policy_for_master" {
  name = "fargate-jnlp-slave-launch-permission-${var.name}"
  policy = templatefile("${path.module}/templates/slave-ecs-task-definition-policy-for-master.json.tpl", {
    region               = data.aws_region.current.name
    account_id           = data.aws_caller_identity.current.account_id
    task_definition_name = aws_ecs_task_definition.fargate_jnlp_slave.family
  })
  role = module.jenkins.ecs_task_role_id
}
