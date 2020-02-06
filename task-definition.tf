data "template_file" "tasks" {
  count = "${length(values(var.service-name))}"

  template = "${file("${path.module}/task-definition/task-service.json")}"

  vars = {
    container_name = "ms-${var.service-name["service-${count.index}"]}"
    repository_url = "${aws_ecr_repository.ecr.*.repository_url[count.index]}"
    service_port = "${var.service-port["service-${count.index}"]}"
    region = "${var.region}"
    log_cluster = "${aws_cloudwatch_log_group.cloudwatch-log-group.name}"
    service_port = "${var.service-port["service-${count.index}"]}"
  }
}

resource "aws_ecs_task_definition" "task-definition-service" {
  count                    = "${length(values(var.service-name))}"
  family                   = "${var.cluster-name}-${var.service-name["service-${count.index}"]}"
  container_definitions    = "${data.template_file.tasks.*.rendered[count.index]}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = "${aws_iam_role.role-ecs-task-definition.arn}"
}

resource "aws_iam_role" "role-ecs-task-definition" {
  name               = "role-ecs-task-definition-${var.cluster-name}"
  assume_role_policy = "${file("${path.module}/policies/ecs-task-role.json")}"
}

resource "aws_iam_policy" "role-ecs-task-definition" {
  name = "task-execution-policy-${var.cluster-name}"
  policy = "${file("${path.module}/policies/ecs-role-task-policy.json")}"
}

resource "aws_iam_role_policy_attachment" "tasks_execution" {
  role       = "${aws_iam_role.role-ecs-task-definition.name}"
  policy_arn = "${aws_iam_policy.role-ecs-task-definition.arn}"
}