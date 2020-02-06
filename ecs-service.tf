resource "aws_ecs_service" "ecs-service" {
  count = "${length(values(var.service-name))}"

  name            = "${var.service-name["service-${count.index}"]}"
  cluster         = "${aws_ecs_cluster.ecs.arn}"
  task_definition = "${aws_ecs_task_definition.task-definition-service.*.arn[count.index]}"
  desired_count   = 2
  #iam_role        = "${aws_iam_role.role-ecs-service.arn}"
  launch_type         = "FARGATE"

  deployment_minimum_healthy_percent = 75
  deployment_maximum_percent         = 200

  depends_on = ["aws_iam_role.role-ecs-service", "aws_alb_target_group.tg-ecs-service-green"]

  network_configuration {
    security_groups = ["${aws_security_group.sg-service.*.id[count.index]}"]
    subnets         = "${var.subnet-node}"
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.tg-ecs-service-green.*.arn[count.index]}"
    container_name   = "ms-${var.service-name["service-${count.index}"]}"
    container_port   = "${var.service-port["service-${count.index}"]}"
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [
      "desired_count",
      "task_definition"
    ]
  }
}

resource "aws_iam_role" "role-ecs-service" {
  name               = "role-ecs-service${var.cluster-name}"
  assume_role_policy = "${file("${path.module}/policies/ecs-service-role.json")}"
}

resource "aws_security_group" "sg-service" {
  count       = "${length(values(var.service-name))}"
  name        = "${var.cluster-name}-${var.service-name["service-${count.index}"]}"
  description = "controls access to the ${var.cluster-name}-${var.service-name["service-${count.index}"]}"
  vpc_id      = "${var.vpc-id}"

  ingress {
    protocol        = "tcp"
    from_port       = "${var.service-port["service-${count.index}"]}"
    to_port         = "${var.service-port["service-${count.index}"]}"
    security_groups = ["${aws_security_group.sg-lb.id}"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

}
