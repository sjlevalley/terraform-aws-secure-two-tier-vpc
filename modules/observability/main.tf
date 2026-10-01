locals {
  log_groups = {
    web_nginx_access = "/${var.name_prefix}/web/nginx/access"
    web_nginx_error  = "/${var.name_prefix}/web/nginx/error"
    web_bootstrap    = "/${var.name_prefix}/web/bootstrap"
    web_system       = "/${var.name_prefix}/web/system"
    app_service      = "/${var.name_prefix}/app/service"
    app_bootstrap    = "/${var.name_prefix}/app/bootstrap"
    app_system       = "/${var.name_prefix}/app/system"
  }
}

data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "this" {
  for_each = local.log_groups

  name              = each.value
  retention_in_days = var.log_retention_days

  tags = merge(var.common_tags, {
    Name = each.value
  })
}


resource "aws_cloudwatch_metric_alarm" "web_unhealthy_hosts" {
  alarm_name          = "${var.name_prefix}-web-unhealthy-hosts"
  alarm_description   = "Web target group has unhealthy hosts."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.public_alb_arn_suffix
    TargetGroup  = var.web_target_group_arn_suffix
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "app_unhealthy_hosts" {
  alarm_name          = "${var.name_prefix}-app-unhealthy-hosts"
  alarm_description   = "App target group has unhealthy hosts."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.internal_alb_arn_suffix
    TargetGroup  = var.app_target_group_arn_suffix
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "public_alb_5xx" {
  alarm_name          = "${var.name_prefix}-public-alb-5xx"
  alarm_description   = "Public ALB is returning HTTP 5xx responses."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.public_alb_arn_suffix
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "internal_alb_5xx" {
  alarm_name          = "${var.name_prefix}-internal-alb-5xx"
  alarm_description   = "Internal ALB is returning HTTP 5xx responses."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.internal_alb_arn_suffix
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "public_alb_high_response_time" {
  alarm_name          = "${var.name_prefix}-public-alb-high-response-time"
  alarm_description   = "Public ALB target response time is high."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.public_alb_arn_suffix
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "internal_alb_high_response_time" {
  alarm_name          = "${var.name_prefix}-internal-alb-high-response-time"
  alarm_description   = "Internal ALB target response time is high."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.internal_alb_arn_suffix
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "web_asg_capacity_below_desired" {
  alarm_name          = "${var.name_prefix}-web-asg-capacity-below-desired"
  alarm_description   = "Web ASG has fewer in-service instances than expected."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  metric_name         = "GroupInServiceInstances"
  namespace           = "AWS/AutoScaling"
  period              = 60
  statistic           = "Average"
  threshold           = 2
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.web_asg_name
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "app_asg_capacity_below_desired" {
  alarm_name          = "${var.name_prefix}-app-asg-capacity-below-desired"
  alarm_description   = "App ASG has fewer in-service instances than expected."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  metric_name         = "GroupInServiceInstances"
  namespace           = "AWS/AutoScaling"
  period              = 60
  statistic           = "Average"
  threshold           = 2
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.app_asg_name
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "web_asg_high_cpu" {
  alarm_name          = "${var.name_prefix}-web-asg-high-cpu"
  alarm_description   = "Web ASG average CPU utilization is high."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.web_asg_name
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "app_asg_high_cpu" {
  alarm_name          = "${var.name_prefix}-app-asg-high-cpu"
  alarm_description   = "App ASG average CPU utilization is high."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.app_asg_name
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "web_asg_high_memory" {
  alarm_name          = "${var.name_prefix}-web-asg-high-memory"
  alarm_description   = "Web ASG memory utilization is high."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.web_asg_name
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "app_asg_high_memory" {
  alarm_name          = "${var.name_prefix}-app-asg-high-memory"
  alarm_description   = "App ASG memory utilization is high."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.app_asg_name
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "web_asg_high_disk" {
  alarm_name          = "${var.name_prefix}-web-asg-high-disk"
  alarm_description   = "Web ASG root disk utilization is high."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.web_asg_name
    path                 = "/"
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "app_asg_high_disk" {
  alarm_name          = "${var.name_prefix}-app-asg-high-disk"
  alarm_description   = "App ASG root disk utilization is high."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.app_asg_name
    path                 = "/"
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2

        properties = {
          markdown = "# ${var.name_prefix} Observability\nALB traffic, target health, Auto Scaling capacity, and instance utilization."
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 12
        height = 6

        properties = {
          title  = "Public ALB Requests"
          region = data.aws_region.current.region
          stat   = "Sum"
          period = 60

          metrics = [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "LoadBalancer",
              var.public_alb_arn_suffix
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 2
        width  = 12
        height = 6

        properties = {
          title  = "ALB 5xx Errors"
          region = data.aws_region.current.region
          stat   = "Sum"
          period = 60

          metrics = [
            [
              "AWS/ApplicationELB",
              "HTTPCode_ELB_5XX_Count",
              "LoadBalancer",
              var.public_alb_arn_suffix,
              {
                label = "Public ALB 5xx"
              }
            ],
            [
              "AWS/ApplicationELB",
              "HTTPCode_ELB_5XX_Count",
              "LoadBalancer",
              var.internal_alb_arn_suffix,
              {
                label = "Internal ALB 5xx"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 12
        height = 6

        properties = {
          title  = "Target Response Time"
          region = data.aws_region.current.region
          stat   = "Average"
          period = 60

          metrics = [
            [
              "AWS/ApplicationELB",
              "TargetResponseTime",
              "LoadBalancer",
              var.public_alb_arn_suffix,
              {
                label = "Public ALB"
              }
            ],
            [
              "AWS/ApplicationELB",
              "TargetResponseTime",
              "LoadBalancer",
              var.internal_alb_arn_suffix,
              {
                label = "Internal ALB"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 8
        width  = 12
        height = 6

        properties = {
          title  = "Unhealthy Hosts"
          region = data.aws_region.current.region
          stat   = "Maximum"
          period = 60

          metrics = [
            [
              "AWS/ApplicationELB",
              "UnHealthyHostCount",
              "LoadBalancer",
              var.public_alb_arn_suffix,
              "TargetGroup",
              var.web_target_group_arn_suffix,
              {
                label = "Web TG"
              }
            ],
            [
              "AWS/ApplicationELB",
              "UnHealthyHostCount",
              "LoadBalancer",
              var.internal_alb_arn_suffix,
              "TargetGroup",
              var.app_target_group_arn_suffix,
              {
                label = "App TG"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 14
        width  = 12
        height = 6

        properties = {
          title  = "ASG In-Service Instances"
          region = data.aws_region.current.region
          stat   = "Average"
          period = 60

          metrics = [
            [
              "AWS/AutoScaling",
              "GroupInServiceInstances",
              "AutoScalingGroupName",
              var.web_asg_name,
              {
                label = "Web ASG"
              }
            ],
            [
              "AWS/AutoScaling",
              "GroupInServiceInstances",
              "AutoScalingGroupName",
              var.app_asg_name,
              {
                label = "App ASG"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 14
        width  = 12
        height = 6

        properties = {
          title  = "ASG CPU"
          region = data.aws_region.current.region
          stat   = "Average"
          period = 60

          metrics = [
            [
              "AWS/EC2",
              "CPUUtilization",
              "AutoScalingGroupName",
              var.web_asg_name,
              {
                label = "Web ASG"
              }
            ],
            [
              "AWS/EC2",
              "CPUUtilization",
              "AutoScalingGroupName",
              var.app_asg_name,
              {
                label = "App ASG"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 20
        width  = 12
        height = 6

        properties = {
          title  = "Memory Used"
          region = data.aws_region.current.region
          stat   = "Average"
          period = 60

          metrics = [
            [
              "CWAgent",
              "mem_used_percent",
              "AutoScalingGroupName",
              var.web_asg_name,
              {
                label = "Web ASG"
              }
            ],
            [
              "CWAgent",
              "mem_used_percent",
              "AutoScalingGroupName",
              var.app_asg_name,
              {
                label = "App ASG"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 20
        width  = 12
        height = 6

        properties = {
          title  = "Root Disk Used"
          region = data.aws_region.current.region
          stat   = "Average"
          period = 60

          metrics = [
            [
              "CWAgent",
              "disk_used_percent",
              "AutoScalingGroupName",
              var.web_asg_name,
              "path",
              "/",
              {
                label = "Web ASG"
              }
            ],
            [
              "CWAgent",
              "disk_used_percent",
              "AutoScalingGroupName",
              var.app_asg_name,
              "path",
              "/",
              {
                label = "App ASG"
              }
            ]
          ]
        }
      }
    ]
  })
}

resource "aws_sns_topic" "alerts" {
  name = "${var.name_prefix}-alerts"

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-alerts"
  })
}

resource "aws_sns_topic_subscription" "email" {
  count = var.alarm_email == null ? 0 : 1

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}
