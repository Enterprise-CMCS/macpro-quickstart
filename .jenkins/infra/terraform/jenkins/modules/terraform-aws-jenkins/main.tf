
locals {
  ebs_volume_name = "${var.prefix}-persistent-data-${var.name}"
  ssl             = var.fqdn_certificate_arn == "" ? false : true
  scheme          = local.ssl == true ? "https" : "http"
  endpoint        = var.fqdn == "" ? aws_alb.alb.dns_name : aws_route53_record.record[0].fqdn
}

data "aws_region" "this" {}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

resource "aws_security_group" "ecs_host" {
  name        = "${var.prefix}-ecs-host-${var.name}"
  description = "Jenkins ECS Host security group"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "ecs_host_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_host.id
}

resource "aws_security_group" "ecs_task" {
  name        = "${var.prefix}-ecs-task-${var.name}"
  description = "Jenkins ECS Task security group"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "ecs_task_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_task.id
}

resource "aws_security_group_rule" "ecs_task_ingress_8080" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.ecs_task.id
}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.prefix}-${var.name}"
}

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

data "template_file" "user_data" {
  template = file("${path.module}/templates/user_data.tpl")
  vars = {
    ecs_cluster_name = "${var.prefix}-${var.name}"
    ebs_region       = data.aws_region.this.name
  }
}

resource "aws_iam_role" "ecs_host" {
  name               = "${var.prefix}-ecs-host-${var.name}"
  assume_role_policy = file("${path.module}/files/assume-role-policy-ec2.json")
}

resource "aws_iam_role_policy" "ecs_host" {
  name   = "${var.prefix}-ecs-host-${var.name}"
  role   = aws_iam_role.ecs_host.id
  policy = file("${path.module}/files/ecs-host-policy.json")
}

resource "aws_iam_instance_profile" "ecs_host" {
  name = "${var.prefix}-ecs-host${var.name}"
  path = "/"
  role = aws_iam_role.ecs_host.name
}


resource "aws_launch_configuration" "ecs_host" {
  name_prefix                 = "${var.prefix}-${var.name}"
  image_id                    = data.aws_ami.ecs_optimized.id
  instance_type               = var.host_instance_type
  security_groups             = flatten([aws_security_group.ecs_host.id, var.host_security_groups])
  key_name                    = var.host_key_name
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ecs_host.name
  user_data                   = data.template_file.user_data.rendered
  root_block_device {
    volume_type = "gp2"
    volume_size = 500
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs_host" {
  name                      = "${var.prefix}-${var.name}"
  min_size                  = 1
  max_size                  = 2
  desired_capacity          = 1
  health_check_type         = "EC2"
  health_check_grace_period = 300
  launch_configuration      = aws_launch_configuration.ecs_host.name
  vpc_zone_identifier       = var.auto_scaling_subnets

  lifecycle {
    create_before_destroy = true
  }

  tags = [
    {
      key                 = "Name"
      value               = "${var.prefix}-${var.name}"
      propagate_at_launch = true
    },
  ]
}

resource "aws_iam_role" "ecs_task" {
  name               = "${var.prefix}-ecs-task-${var.name}"
  assume_role_policy = file("${path.module}/files/assume-role-policy-ecs-tasks.json")
}

data "template_file" "ecs_task" {
  template = file("${path.module}/templates/ecs-task.json.tpl")
  vars = {
    image           = var.image
    ebs_volume_name = local.ebs_volume_name
  }
}

resource "aws_ebs_volume" "jenkins_home" {
  availability_zone = var.auto_scaling_availability_zone
  size              = var.jenkins_home_size
  snapshot_id       = var.jenkins_home_snapshot_id
  tags = {
    Name = local.ebs_volume_name
  }
}

resource "aws_ecs_task_definition" "ecs_task" {
  family                = "${var.prefix}-${var.name}"
  container_definitions = data.template_file.ecs_task.rendered
  task_role_arn         = aws_iam_role.ecs_task.arn
  network_mode          = "awsvpc"
  volume {
    name = local.ebs_volume_name
    docker_volume_configuration {
      scope         = "shared"
      autoprovision = false
      driver        = "rexray/ebs"
    }
  }
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
}

resource "aws_service_discovery_private_dns_namespace" "jenkins" {
  name        = "jenkins-${var.name}.local"
  description = "${var.prefix}-private-dns-${var.name}"
  vpc         = var.vpc_id
}

resource "aws_service_discovery_service" "jenkins" {
  name = "jenkins"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.jenkins.id
    dns_records {
      ttl  = 5
      type = "A"
    }
    routing_policy = "WEIGHTED"
  }
}

resource "aws_ecs_service" "ecs_service" {
  name                              = "${var.prefix}-${var.name}"
  cluster                           = aws_ecs_cluster.cluster.id
  task_definition                   = aws_ecs_task_definition.ecs_task.arn
  desired_count                     = 1
  health_check_grace_period_seconds = 300

  network_configuration {
    subnets          = var.auto_scaling_subnets
    security_groups  = [aws_security_group.ecs_task.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.target_group.id
    container_name   = "jenkins"
    container_port   = "8080"
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.jenkins.arn
    container_name = "jenkins"
  }

  depends_on = [aws_autoscaling_group.ecs_host]
}

resource "aws_security_group" "alb" {
  name        = "${var.prefix}-alb-${var.name}"
  description = "Jenkins Application Load Balancer security group for ${var.name}"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "alb_egress" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_task.id
  security_group_id        = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_ingress_80" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_ingress_443" {
  count             = local.ssl == true ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_alb_target_group" "target_group" {
  name                 = "${var.prefix}-${var.name}"
  port                 = 8080
  target_type          = "ip"
  protocol             = "HTTP"
  deregistration_delay = "10"
  vpc_id               = var.vpc_id
  health_check {
    path                = "/"
    port                = "8080"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 5
    timeout             = 4
    matcher             = "200,403"
  }
  depends_on = [aws_alb.alb]
}

resource "aws_alb" "alb" {
  name            = "${var.prefix}-${var.name}"
  internal        = var.load_balancer_internal
  subnets         = var.load_balancer_subnets
  security_groups = [aws_security_group.alb.id]
}

# Conditionally create an ALB listener which forwards 443 traffic to the jenkins target group.
resource "aws_alb_listener" "https_forward" {
  count             = local.ssl == true ? 1 : 0
  load_balancer_arn = aws_alb.alb.id
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.fqdn_certificate_arn
  default_action {
    target_group_arn = aws_alb_target_group.target_group.id
    type             = "forward"
  }
}

# Conditionally create an ALB listener which forwards 80 traffic to the jenkins target group.
resource "aws_alb_listener" "http_forward" {
  count             = local.ssl == true ? 0 : 1
  load_balancer_arn = aws_alb.alb.id
  port              = "80"
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_alb_target_group.target_group.id
    type             = "forward"
  }
}

# Conditionally create an ALB listener which redirects 80 traffic to 443
resource "aws_alb_listener" "http_to_https_redirect" {
  count             = local.ssl == true ? 1 : 0
  load_balancer_arn = aws_alb.alb.id
  port              = "80"
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_alb_target_group.target_group.id
    type             = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_302"
    }
  }
}

data "aws_route53_zone" "zone" {
  count = var.fqdn == "" ? 0 : 1
  name  = var.fqdn_hosted_zone
}

resource "aws_route53_record" "record" {
  count   = var.fqdn == "" ? 0 : 1
  zone_id = data.aws_route53_zone.zone[0].zone_id
  name    = var.fqdn
  type    = "CNAME"
  ttl     = "5"
  records = [aws_alb.alb.dns_name]
}

resource "aws_iam_role" "dlm_lifecycle_role" {
  name               = "${var.prefix}-dlm-lifecycle-role-${var.name}"
  assume_role_policy = file("${path.module}/files/assume-role-policy-dlm.json")
}

resource "aws_iam_role_policy" "dlm_lifecycle" {
  name   = "${var.prefix}-dlm-lifecycle-policy-${var.name}"
  role   = aws_iam_role.dlm_lifecycle_role.id
  policy = file("${path.module}/files/dlm-policy.json")
}

resource "aws_dlm_lifecycle_policy" "example" {
  description        = "Jenkins DLM Lifecycle Policy ${var.name}"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state              = "ENABLED"
  policy_details {
    resource_types = ["VOLUME"]
    schedule {
      name = "2 weeks of daily snapshots"
      create_rule {
        interval      = 2
        interval_unit = "HOURS"
        times         = ["00:00"]
      }
      retain_rule {
        count = 168
      }
      tags_to_add = {
        SnapshotCreator = "DLM"
        SourceVolume    = local.ebs_volume_name
      }
      copy_tags = true
    }
    target_tags = {
      Name = local.ebs_volume_name
    }
  }
}
