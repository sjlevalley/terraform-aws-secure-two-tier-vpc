resource "aws_lb" "internal" {
  name               = "${var.name_prefix}-internal"
  internal           = true
  load_balancer_type = "application"

  security_groups = [var.internal_alb_security_group_id]
  subnets         = values(var.private_subnet_ids)

  enable_deletion_protection = false
  drop_invalid_header_fields = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-internal-alb"
    Tier = "internal-load-balancer"
  })
}


resource "aws_lb_target_group" "app" {
  name        = "${var.name_prefix}-app-tg"
  port        = var.app_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-app-tg"
    Tier = "application"
  })
}



resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.internal.arn
  port              = var.app_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}


resource "aws_lb" "public" {
  name               = "${var.name_prefix}-public"
  internal           = false
  load_balancer_type = "application"

  security_groups = [var.public_alb_security_group_id]
  subnets         = values(var.public_subnet_ids)

  enable_deletion_protection = false
  drop_invalid_header_fields = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-public-alb"
    Tier = "public-load-balancer"
  })
}

resource "aws_lb_target_group" "web" {
  name        = "${var.name_prefix}-web-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-web-tg"
    Tier = "web"
  })
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}


resource "aws_lb_listener" "web_https" {
  load_balancer_arn = aws_lb.public.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

