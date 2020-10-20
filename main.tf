#TODO:
# - move module to separate repo
# - string/number cleanup
# - delete ebs volume on termination

provider "aws" {
  region = var.region
}

locals {
  tags = merge({
    Description = "S3 Proxy"
    CreatedBy   = "Terraform"
    Role        = "networkcore"
    Environment = var.environment
    Name        = "s3proxy"
  }, var.tags)
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "this" {
  key_name   = "s3proxy"
  public_key = tls_private_key.this.public_key_openssh
  tags = merge(local.tags, {
    Description = "sshkey for s3proxy instances"
  })
}

resource "aws_security_group" "instance" {
  name   = "s3proxy-instance"
  vpc_id = var.vpc_id

  # ping
  ingress {
    from_port   = 0
    to_port     = 8
    protocol    = "icmp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  # ssh
  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "TCP"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  # squid
  ingress {
    from_port   = var.proxy_port
    to_port     = var.proxy_port
    protocol    = "TCP"
    cidr_blocks = [var.proxy_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = var.egress_allowed_cidr
  }
}

resource "aws_launch_configuration" "s3proxy" {
  name_prefix                 = "s3proxy"
  image_id                    = data.aws_ami.centos.id
  instance_type               = var.instance_type
  associate_public_ip_address = false
  key_name                    = aws_key_pair.this.key_name
  security_groups             = [aws_security_group.instance.id]

  user_data = templatefile("${path.module}/user_data.sh.tmpl", {
    proxy_port         = var.proxy_port
    proxy_allowed_cidr = var.proxy_allowed_cidr
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "s3proxy" {
  name                 = "s3proxy"
  launch_configuration = aws_launch_configuration.s3proxy.name
  vpc_zone_identifier  = var.subnet_ids

  health_check_type = "ELB"

  target_group_arns = [
    aws_lb_target_group.http.arn,
  ]

  lifecycle {
    create_before_destroy = true
  }

  min_size = var.min_size
  max_size = var.max_size

  enabled_metrics = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]

  tags = [for k, v in merge(local.tags, {}) : {
    key                 = k
    value               = v
    propagate_at_launch = true
  }]
}

# auto scale up policy
resource "aws_autoscaling_policy" "s3proxy_up" {
  name                   = "s3proxy-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.s3proxy.name
}

# auto scale down policy
resource "aws_autoscaling_policy" "s3proxy_down" {
  name                   = "s3proxy-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.s3proxy.name
}

resource "aws_cloudwatch_metric_alarm" "s3proxy_up" {
  alarm_name          = "s3proxy-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Check whether EC2 instance CPU utilisation is over 80% on average"
  alarm_actions       = [aws_autoscaling_policy.s3proxy_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.s3proxy.name
  }
  tags = merge(local.tags, {
    Name        = "s3proxy-up"
    Description = "trigger for scale-up of s3proxy farm"
  })
}

resource "aws_cloudwatch_metric_alarm" "s3proxy_down" {
  alarm_name          = "s3proxy-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "20"
  alarm_description   = "Check whether EC2 instance CPU utilisation is under 20% on average"
  alarm_actions       = [aws_autoscaling_policy.s3proxy_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.s3proxy.name
  }
  tags = merge(local.tags, {
    Name        = "s3proxy-up"
    Description = "trigger for scale-down of s3proxy farm"
  })
}

resource "aws_lb" "s3proxy" {
  name                             = "s3proxy"
  internal                         = true
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = true
  subnets                          = var.subnet_ids
  tags                             = local.tags
}

resource "aws_lb_target_group" "http" {
  name     = "s3proxy-http"
  protocol = "TCP"
  port     = 3128
  vpc_id   = var.vpc_id
  tags = merge(local.tags, {
    Description = "S3 Proxy ELB target group"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.s3proxy.arn
  protocol          = "TCP"
  port              = 80

  default_action {
    target_group_arn = aws_lb_target_group.http.arn
    type             = "forward"
  }
}
