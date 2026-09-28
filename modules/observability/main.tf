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