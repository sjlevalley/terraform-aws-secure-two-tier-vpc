resource "aws_security_group" "web" {
  name        = "${var.name_prefix}-web-sg"
  description = "Allows HTTP traffic to the web tier"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-web-sg"
    Tier = "web"
  })
}

resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-app-sg"
  description = "Allows application traffic only from the internal ALB"
  vpc_id      = var.vpc_id


  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-app-sg"
    Tier = "application"
  })
}



resource "aws_security_group" "internal_alb" {
  name        = "${var.name_prefix}-internal-alb-sg"
  description = "Controls traffic through the internal application load balancer"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-internal-alb-sg"
    Tier = "internal-load-balancer"
  })
}


resource "aws_vpc_security_group_ingress_rule" "internal_alb_from_web" {
  security_group_id            = aws_security_group.internal_alb.id
  referenced_security_group_id = aws_security_group.web.id
  description                  = "Application requests from the web tier"
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

resource "aws_vpc_security_group_egress_rule" "internal_alb_to_app" {
  security_group_id            = aws_security_group.internal_alb.id
  referenced_security_group_id = aws_security_group.app.id
  description                  = "Forward application requests to the app tier"
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

resource "aws_vpc_security_group_ingress_rule" "app_from_internal_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.internal_alb.id
  description                  = "Application traffic from the internal ALB"
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}


resource "aws_security_group" "public_alb" {
  name        = "${var.name_prefix}-public-alb-sg"
  description = "Allows public HTTP traffic to the public ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
  description = "HTTPS from the internet"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-public-alb-sg"
    Tier = "public-load-balancer"
  })
}


resource "aws_vpc_security_group_egress_rule" "public_alb_to_web" {
  security_group_id            = aws_security_group.public_alb.id
  referenced_security_group_id = aws_security_group.web.id
  description                  = "Forward HTTP requests to the web tier"
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}

resource "aws_vpc_security_group_ingress_rule" "web_from_public_alb" {
  security_group_id            = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.public_alb.id
  description                  = "HTTP from the public ALB"
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}