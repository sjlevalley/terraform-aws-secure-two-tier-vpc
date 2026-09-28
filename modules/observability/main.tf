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