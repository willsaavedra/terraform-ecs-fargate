resource "aws_cloudwatch_log_group" "cloudwatch-log-group" {
  name = "ecs-cluster-${var.cluster-name}"
}