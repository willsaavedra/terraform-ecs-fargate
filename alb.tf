resource "aws_alb" "alb-ecs" {
  name            = "alb-${var.cluster-name}"
  subnets         = "${var.subnet-node}"
  security_groups = ["${aws_security_group.sg-lb.id}"]
  internal        = "${var.internal}"
}

resource "aws_alb_target_group" "tg-ecs-service-blue" {
  count       = "${length(values(var.service-name))}"
  name        = "tg-${var.cluster-name}-${var.service-name["service-${count.index}"]}-blue"
  port        = "${var.service-port["service-${count.index}"]}"
  protocol    = "HTTP"
  vpc_id      = "${var.vpc-id}"
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "${var.health["service-${count.index}"]}"
    unhealthy_threshold = "2"
  }
}

resource "aws_alb_target_group" "tg-ecs-service-green" {
  count       = "${length(values(var.service-name))}"
  name        = "tg-${var.cluster-name}-${var.service-name["service-${count.index}"]}-green"
  port        = "${var.service-port["service-${count.index}"]}"
  protocol    = "HTTP"
  vpc_id      = "${var.vpc-id}"
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "${var.health["service-${count.index}"]}"
    unhealthy_threshold = "2"
  }
}

resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = "${aws_alb.alb-ecs.arn}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "200"
    }
  }
}

resource "aws_alb_listener_rule" "alb_listener_rule" {
  count        = "${length(values(var.service-name))}"
  listener_arn = "${aws_alb_listener.alb_listener.arn}"

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.tg-ecs-service-green.*.arn[count.index]}"
  }

  condition {
    field  = "host-header"
    values = ["${var.dns-service["service-${count.index}"]}"]
  }
}

resource "aws_security_group" "sg-lb" {
  name        = "alb-${var.cluster-name}-${var.cluster-name}"
  description = "controls access to the ALB"
  vpc_id      = "${var.vpc-id}"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    description = "VIX"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
