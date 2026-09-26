data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}



resource "aws_launch_template" "web" {
  name_prefix   = "${var.name_prefix}-web-"
  image_id      = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.web_security_group_id]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      encrypted             = true
      volume_type           = "gp3"
      volume_size           = var.root_volume_size
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile(
    "${path.module}/templates/web-user-data.sh.tftpl",
    {
      instance_name         = "web-asg"
      internal_alb_dns_name = var.internal_alb_dns_name
      app_port              = var.app_port
    }
  ))

  tag_specifications {
    resource_type = "instance"

    tags = merge(var.common_tags, {
      Name = "${var.name_prefix}-web-asg"
      Tier = "web"
    })
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(var.common_tags, {
      Name = "${var.name_prefix}-web-asg-root"
      Tier = "web"
    })
  }
}


resource "aws_launch_template" "app" {
  name_prefix   = "${var.name_prefix}-app-"
  image_id      = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.app_security_group_id]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      encrypted             = true
      volume_type           = "gp3"
      volume_size           = var.root_volume_size
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile(
    "${path.module}/templates/app-user-data.sh.tftpl",
    {}
  ))

  tag_specifications {
    resource_type = "instance"

    tags = merge(var.common_tags, {
      Name = "${var.name_prefix}-app-asg"
      Tier = "application"
    })
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(var.common_tags, {
      Name = "${var.name_prefix}-app-asg-root"
      Tier = "application"
    })
  }
}


resource "aws_autoscaling_group" "web" {
  name                = "${var.name_prefix}-web-asg"
  min_size            = 2
  desired_capacity    = 2
  max_size            = 4
  vpc_zone_identifier = values(var.private_subnet_ids)
  target_group_arns   = [var.web_target_group_arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-web-asg"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.common_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}


resource "aws_autoscaling_group" "app" {
  name                = "${var.name_prefix}-app-asg"
  min_size            = 2
  desired_capacity    = 2
  max_size            = 4
  vpc_zone_identifier = values(var.private_subnet_ids)
  target_group_arns   = [var.app_target_group_arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-app-asg"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.common_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
